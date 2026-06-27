#!/usr/bin/env python3
"""
extract_callgraph.py — Build a structured call graph from Fortran source.

Walks a directory of .f90/.F90/.f/.F files, parses each with fparser2,
identifies all subroutine/function definitions and their call sites,
and emits:
  - callgraph.json       (full graph: nodes, edges, metadata)
  - callgraph.dot        (Graphviz DOT, for rendering if needed)
  - callgraph_summary.txt (flattened text summary for LLM context)

Usage:
    python3 extract_callgraph.py <source_dir> [output_dir]
"""

import sys
import os
import json
from pathlib import Path

import networkx as nx
from fparser.common.readfortran import FortranFileReader
from fparser.two.parser import ParserFactory
from fparser.two.utils import walk
from fparser.two import Fortran2003 as F03


def find_fortran_files(source_dir):
    """Recursively find all Fortran source files."""
    exts = (".f90", ".F90", ".f", ".F", ".f95", ".F95")
    files = []
    for root, _, fnames in os.walk(source_dir):
        for fname in fnames:
            if fname.endswith(exts):
                files.append(os.path.join(root, fname))
    return sorted(files)


def get_name(node):
    """Best-effort extraction of a name string from an fparser2 node."""
    try:
        return str(node).strip()
    except Exception:
        return None


def extract_procedures_and_calls(filepath, parser):
    """
    Parse one file. Return:
      procedures: list of dicts {name, kind, file, line}
      calls: list of dicts {caller, callee, file, line}
      module_name: str or None
    """
    procedures = []
    calls = []
    module_name = None

    try:
        reader = FortranFileReader(filepath, ignore_comments=False)
        tree = parser(reader)
    except Exception as e:
        return procedures, calls, module_name, f"PARSE_ERROR: {e}"

    # Find module name
    for mod in walk(tree, F03.Module_Stmt):
        module_name = get_name(mod.items[1])
        break

    # Walk all subroutine and function subprograms
    proc_nodes = list(walk(tree, F03.Subroutine_Subprogram)) + \
                 list(walk(tree, F03.Function_Subprogram))

    for proc in proc_nodes:
        # Get the name and kind
        sub_stmt = None
        kind = None
        for child in walk(proc, F03.Subroutine_Stmt):
            sub_stmt = child
            kind = "subroutine"
            break
        if sub_stmt is None:
            for child in walk(proc, F03.Function_Stmt):
                sub_stmt = child
                kind = "function"
                break

        if sub_stmt is None:
            continue

        # Name is typically items[1] for Subroutine_Stmt / Function_Stmt
        try:
            proc_name = get_name(sub_stmt.items[1])
        except Exception:
            continue

        procedures.append({
            "name": proc_name,
            "kind": kind,
            "file": filepath,
            "module": module_name,
        })

        # Find all call statements within this procedure
        for call_stmt in walk(proc, F03.Call_Stmt):
            try:
                callee_name = get_name(call_stmt.items[0])
            except Exception:
                continue
            calls.append({
                "caller": proc_name,
                "callee": callee_name,
                "file": filepath,
            })

        # Also catch function calls used as expressions (Part_Ref / function calls)
        # This is heuristic — fparser2 doesn't cleanly distinguish array indexing
        # from function calls without a symbol table, so we cross-reference later
        # against the known procedure list.
        for part_ref in walk(proc, F03.Part_Ref):
            try:
                callee_name = get_name(part_ref.items[0])
            except Exception:
                continue
            calls.append({
                "caller": proc_name,
                "callee": callee_name,
                "file": filepath,
                "heuristic": True,  # may be array indexing, not a real call
            })

    return procedures, calls, module_name, None


def build_graph(source_dir):
    parser = ParserFactory().create(std="f2008")
    files = find_fortran_files(source_dir)

    all_procedures = []
    all_calls = []
    errors = []

    for filepath in files:
        procs, calls, module_name, err = extract_procedures_and_calls(filepath, parser)
        all_procedures.extend(procs)
        all_calls.extend(calls)
        if err:
            errors.append({"file": filepath, "error": err})

    known_names = {p["name"].lower() for p in all_procedures if p["name"]}

    # Filter heuristic Part_Ref calls down to only those matching known procedure names
    # (removes array-indexing false positives)
    confirmed_calls = []
    for c in all_calls:
        if c.get("heuristic"):
            if c["callee"] and c["callee"].lower() in known_names:
                confirmed_calls.append(c)
        else:
            confirmed_calls.append(c)

    # Build the graph
    G = nx.DiGraph()
    for p in all_procedures:
        G.add_node(p["name"], kind=p["kind"], file=p["file"], module=p["module"])

    for c in confirmed_calls:
        if c["callee"]:
            G.add_edge(c["caller"], c["callee"], file=c["file"])

    return G, all_procedures, confirmed_calls, errors


def write_outputs(G, procedures, calls, errors, output_dir):
    os.makedirs(output_dir, exist_ok=True)

    # 1. JSON output
    data = {
        "nodes": [
            {"name": n, **G.nodes[n]} for n in G.nodes
        ],
        "edges": [
            {"caller": u, "callee": v} for u, v in G.edges
        ],
        "errors": errors,
    }
    with open(os.path.join(output_dir, "callgraph.json"), "w") as f:
        json.dump(data, f, indent=2)

    # 2. DOT output
    nx.drawing.nx_pydot.write_dot(G, os.path.join(output_dir, "callgraph.dot")) \
        if _has_pydot() else write_dot_manual(G, os.path.join(output_dir, "callgraph.dot"))

    # 3. Flattened text summary for LLM context
    lines = []
    lines.append(f"FORTRAN CALL GRAPH SUMMARY")
    lines.append(f"Total procedures: {len(G.nodes)}")
    lines.append(f"Total call edges: {len(G.edges)}")
    lines.append("")

    # Unreferenced procedures (potential dead code)
    unreferenced = [n for n in G.nodes if G.in_degree(n) == 0]
    lines.append(f"=== Never called (potential dead code or entry points): {len(unreferenced)} ===")
    for n in sorted(unreferenced):
        kind = G.nodes[n].get("kind", "?")
        file = os.path.basename(G.nodes[n].get("file", "?"))
        lines.append(f"  {n} ({kind}) — {file}")
    lines.append("")

    # Most-called procedures (hotspots)
    in_degrees = sorted(G.in_degree, key=lambda x: -x[1])
    lines.append("=== Most-called procedures (top 15) ===")
    for name, deg in in_degrees[:15]:
        if deg > 0:
            lines.append(f"  {name}: called by {deg} procedure(s)")
    lines.append("")

    # Procedures with most outgoing calls (complexity indicator)
    out_degrees = sorted(G.out_degree, key=lambda x: -x[1])
    lines.append("=== Procedures with most outgoing calls (top 15) ===")
    for name, deg in out_degrees[:15]:
        if deg > 0:
            lines.append(f"  {name}: calls {deg} other procedure(s)")
    lines.append("")

    # Deepest call chains
    lines.append("=== Call graph structure (per-procedure callees) ===")
    for n in sorted(G.nodes):
        callees = list(G.successors(n))
        if callees:
            lines.append(f"  {n} -> {', '.join(sorted(callees))}")
    lines.append("")

    # Cycles (recursive or mutually recursive chains)
    try:
        cycles = list(nx.simple_cycles(G))
        if cycles:
            lines.append(f"=== Cycles detected (recursion): {len(cycles)} ===")
            for cycle in cycles[:20]:
                lines.append(f"  {' -> '.join(cycle)} -> {cycle[0]}")
        else:
            lines.append("=== No cycles detected ===")
    except Exception as e:
        lines.append(f"=== Cycle detection failed: {e} ===")
    lines.append("")

    if errors:
        lines.append(f"=== Parse errors: {len(errors)} ===")
        for e in errors:
            lines.append(f"  {e['file']}: {e['error']}")

    with open(os.path.join(output_dir, "callgraph_summary.txt"), "w") as f:
        f.write("\n".join(lines))

    return data


def _has_pydot():
    try:
        import pydot  # noqa
        return True
    except ImportError:
        return False


def write_dot_manual(G, path):
    """Fallback DOT writer if pydot isn't available."""
    with open(path, "w") as f:
        f.write("digraph callgraph {\n")
        for n in G.nodes:
            kind = G.nodes[n].get("kind", "")
            shape = "box" if kind == "subroutine" else "ellipse"
            f.write(f'  "{n}" [shape={shape}];\n')
        for u, v in G.edges:
            f.write(f'  "{u}" -> "{v}";\n')
        f.write("}\n")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 extract_callgraph.py <source_dir> [output_dir]")
        sys.exit(1)

    source_dir = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else "./callgraph_output"

    print(f"Scanning {source_dir}...")
    G, procedures, calls, errors = build_graph(source_dir)
    print(f"Found {len(procedures)} procedures, {len(calls)} call edges, {len(errors)} parse errors")

    write_outputs(G, procedures, calls, errors, output_dir)
    print(f"Output written to {output_dir}/")
    print(f"  - callgraph.json")
    print(f"  - callgraph.dot")
    print(f"  - callgraph_summary.txt")
