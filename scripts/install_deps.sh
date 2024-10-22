#!/bin/bash

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS_DIR="${SCRIPT_DIR}/../dependencies"
DISTROBOX_CONFIG="${SCRIPT_DIR}/../distrobox.ini"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status messages
log() { echo -e "${GREEN}==>${NC} $1"; }
warn() { echo -e "${YELLOW}WARNING:${NC} $1"; }
error() { echo -e "${RED}ERROR:${NC} $1"; exit 1; }
info() { echo -e "${BLUE}INFO:${NC} $1"; }

# List available dependency files
list_deps_files() {
    echo "Available dependency configurations:"
    for file in "$DEPS_DIR"/*.txt; do
        name=$(basename "$file" .txt)
        if [ -f "$file.description" ]; then
            description=$(cat "$file.description")
            echo -e "${BLUE}${name}${NC}: ${description}"
        else
            echo -e "${BLUE}${name}${NC}"
        fi
    done
}

# Select dependency files
select_deps_files() {
    local selected_files=()
    local deps_files=("$DEPS_DIR"/*.txt)
    
    echo "Select dependency files to include (space-separated numbers, press enter when done):"
    select file in "${deps_files[@]}" "Done"; do
        case $file in
            "Done")
                break
                ;;
            *)
                if [[ " ${selected_files[@]} " =~ " ${file} " ]]; then
                    warn "Already selected: $(basename "$file")"
                else
                    selected_files+=("$file")
                    log "Added: $(basename "$file")"
                fi
                ;;
        esac
    done
    
    echo "${selected_files[@]}"
}

# Merge selected dependency files
merge_deps_files() {
    local temp_file=$(mktemp)
    local current_category=""
    local seen_packages=()
    
    for deps_file in "$@"; do
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip empty lines and comments
            [[ -z "$line" ]] || [[ "$line" =~ ^#.*$ ]] && continue
            
            # Handle category lines
            if [[ "$line" =~ ^\[(.*)\]$ ]]; then
                current_category="${BASH_REMATCH[1]}"
                if [[ ! " ${seen_categories[@]} " =~ " ${current_category} " ]]; then
                    echo "$line" >> "$temp_file"
                    seen_categories+=("$current_category")
                fi
                continue
            fi
            
            # Handle package lines
            if [ -n "$current_category" ]; then
                package_base=$(echo "$line" | cut -d'|' -f1 | xargs)
                if [[ ! " ${seen_packages[@]} " =~ " ${package_base} " ]]; then
                    echo "$line" >> "$temp_file"
                    seen_packages+=("$package_base")
                fi
            fi
        done < "$deps_file"
    done
    
    echo "$temp_file"
}

# Rest of the existing functions (detect_package_manager, get_package_name, install_packages, etc.)
# ... (keep all the existing functions from the previous script)

# Modified main script to handle multiple dependency files
main() {
    local mode=$1
    shift

    case $mode in
        list)
            list_deps_files
            ;;
        install)
            local deps_files
            if [ $# -eq 0 ]; then
                # Interactive selection if no files specified
                deps_files=($(select_deps_files))
            else
                # Use specified files
                for file in "$@"; do
                    if [ -f "$DEPS_DIR/$file.txt" ]; then
                        deps_files+=("$DEPS_DIR/$file.txt")
                    else
                        error "Dependency file not found: $file.txt"
                    fi
                done
            fi
            
            if [ ${#deps_files[@]} -eq 0 ]; then
                error "No dependency files selected"
            fi
            
            local merged_deps=$(merge_deps_files "${deps_files[@]}")
            DEPS_FILE="$merged_deps" install_packages
            rm -f "$merged_deps"
            ;;
        generate-distrobox)
            local name=$1
            local image=$2
            local deps_files
            shift 2
            
            if [ $# -eq 0 ]; then
                deps_files=($(select_deps_files))
            else
                for file in "$@"; do
                    if [ -f "$DEPS_DIR/$file.txt" ]; then
                        deps_files+=("$DEPS_DIR/$file.txt")
                    else
                        error "Dependency file not found: $file.txt"
                    fi
                done
            fi
            
            local merged_deps=$(merge_deps_files "${deps_files[@]}")
            DEPS_FILE="$merged_deps" generate_distrobox_config "$name" "$image"
            rm -f "$merged_deps"
            ;;
        *)
            error "Usage: $0 {list|install [config-names...]|generate-distrobox <name> <image> [config-names...]}"
            ;;
    esac
}

# Run the script
main "$@"
