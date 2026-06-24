#!/bin/bash

################################################################################
# check_processes.sh
# 
# Description: Verifies if specified processes are running on the system.
#              Returns 0 (success) if all processes are running, 1 (failure) otherwise.
#
# Usage: ./check_processes.sh [process_names...]
#        ./check_processes.sh nginx sshd curl
#
# Author: DevOps Team
################################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_status() {
    local status=$1
    local message=$2
    
    case "$status" in
        "success")
            echo -e "${GREEN}✓${NC} $message"
            ;;
        "error")
            echo -e "${RED}✗${NC} $message"
            ;;
        "warning")
            echo -e "${YELLOW}⚠${NC} $message"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Function to check if a process is running
check_process() {
    local process_name=$1
    
    if pgrep -x "$process_name" > /dev/null; then
        print_status "success" "Process '$process_name' is running"
        return 0
    else
        print_status "error" "Process '$process_name' is NOT running"
        return 1
    fi
}

# Main script logic
main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 [process_names...]"
        echo "Example: $0 nginx sshd curl"
        echo ""
        echo "This script checks if the specified processes are running."
        exit 1
    fi

    echo "=========================================="
    echo "Process Status Check"
    echo "=========================================="
    echo "Timestamp: $(date)"
    echo "Hostname: $(hostname)"
    echo ""

    local failed_processes=()
    local passed_processes=()

    # Check each process
    for process in "$@"; do
        if check_process "$process"; then
            passed_processes+=("$process")
        else
            failed_processes+=("$process")
        fi
    done

    # Summary
    echo ""
    echo "=========================================="
    echo "Summary"
    echo "=========================================="
    echo "Total processes checked: $#"
    echo "Passed: ${#passed_processes[@]}"
    echo "Failed: ${#failed_processes[@]}"
    echo ""

    if [[ ${#failed_processes[@]} -gt 0 ]]; then
        echo -e "${RED}Failed processes:${NC}"
        for process in "${failed_processes[@]}"; do
            echo "  - $process"
        done
        echo ""
        print_status "error" "Health check FAILED"
        return 1
    else
        print_status "success" "All processes are running - Health check PASSED"
        return 0
    fi
}

# Run main function
main "$@"
