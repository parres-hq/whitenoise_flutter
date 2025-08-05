#!/bin/bash
set -euo pipefail

MIN_COVERAGE=100
FILE_PATTERN="provider"
BASE_BRANCH="master"

print_error() {
    red_color="\e[31;1m%s\e[0m\n"
    printf "${red_color}" "$1"
}

print_success() {
    green_color="\e[32;1m%s\e[0m\n"
    printf "${green_color}" "$1"
}

raise_error() {
    print_error "$1"
    exit 1
}

check_prerequisites() {
    local missing_tools=()
    
    command -v git >/dev/null 2>&1 || missing_tools+=("git")
    command -v lcov >/dev/null 2>&1 || missing_tools+=("lcov")
    command -v bc >/dev/null 2>&1 || missing_tools+=("bc")
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        local tools_list=$(printf ", %s" "${missing_tools[@]}")
        tools_list=${tools_list:2}  # Remove leading ", "
        raise_error "Missing required tools: ${tools_list}. Please install them first."
    fi
}

check_coverage_file_presence() {
  if [ ! -f "coverage/lcov.info" ]; then
    raise_error "Coverage file not found. Run 'flutter test --coverage' first."
  fi
}

get_merge_base() {
    local base_branch=$1
    merge_base=$(git merge-base HEAD "origin/${base_branch}" 2>/dev/null || git merge-base HEAD "${base_branch}" 2>/dev/null)
    echo "$merge_base"
}

check_merge_base() {
    local base_branch=$1
    local merge_base=$2
    if [ -z "$merge_base" ]; then
        raise_error "Could not find common ancestor with ${base_branch}"
    fi
}

get_changed_files() {
    local merge_base=$1
    local file_pattern=$2
    changed_files=$(git diff --name-only "${merge_base}..HEAD" | grep '^lib/.*\.dart$' | grep "${file_pattern}" || true)

    if [ -z "$changed_files" ]; then
        print_success "No lib/ Dart files matching '${file_pattern}' changed. Skipping coverage check."
        exit 0
    fi
    echo "$changed_files"
}

make_temp_file() {
    local temp_lcov=$(mktemp)
    trap "rm -f $temp_lcov" EXIT
    echo "$temp_lcov"
}

calculate_coverage() {
    local changed_files=$1
    local temp_lcov=$2

    # Convert newline-separated files to array to avoid word splitting issues
    local -a files_array
    while IFS= read -r file; do
        files_array+=("$file")
    done <<< "$changed_files"
    
    lcov --quiet --extract coverage/lcov.info "${files_array[@]}" --output-file "$temp_lcov" >/dev/null 2>&1
}


check_coverage_data_presence() {
    local changed_files=$1
    local temp_lcov=$2
    if [ ! -s "$temp_lcov" ] || ! grep -q "end_of_record" "$temp_lcov"; then
        file_list=$(echo "$changed_files" | sed 's/^/  - /')
        raise_error "No coverage data for changed files. Add tests for:\n${file_list}"
    fi

}

extract_coverage_percentage() {
    local temp_lcov=$1
    local coverage_percentage
    coverage_percentage=$(lcov --quiet --list "$temp_lcov" 2>/dev/null | grep -v "Message summary" | sed -n "s/.*Total:|\([^%]*\)%.*/\1/p")
    echo "$coverage_percentage"
}

print_files_with_low_coverage() {
    local temp_lcov=$1
    local min_coverage=$2
    print_error "Files with coverage issues:"
    
    lcov --quiet --list "$temp_lcov" 2>/dev/null | grep -v "Message summary" | grep -E "^[^|]*\|" | grep -v "Total:" | while IFS='|' read -r file coverage rest; do
        pct=$(echo "$coverage" | sed 's/[^0-9.]//g')
        if [ -n "$pct" ] && (($(echo "$pct < $min_coverage" | bc -l))); then
            print_error "  - $file"
        fi
    done
}

handle_coverage_failure() {
    local temp_lcov=$1
    local coverage_percentage=$2
    local min_coverage=$3
    print_error "Coverage under ${min_coverage}%"
    print_files_with_low_coverage "$temp_lcov" "$min_coverage"
    exit 1
}

check_coverage_result() {
    local temp_lcov=$1
    local coverage_percentage=$2
    local min_coverage=$3
    
    if ! check_coverage_threshold "$coverage_percentage"; then
        handle_coverage_failure "$temp_lcov" "$coverage_percentage" "$min_coverage"
    fi

    print_success "Coverage ${coverage_percentage}% ✓" 
}

check_coverage_threshold() {
    local coverage_percentage=$1
    if [ -n "$coverage_percentage" ] && (($(echo "$coverage_percentage >= $MIN_COVERAGE" | bc -l))); then
        return 0
    else
        return 1
    fi
}


check_diff_coverage() {
    printf "Checking coverage for changed files...\n"
    local base_branch=$1
    local file_pattern=$2
    local min_coverage=$3
    check_prerequisites
    check_coverage_file_presence
    merge_base=$(get_merge_base "$base_branch")
    check_merge_base "$base_branch" "$merge_base"
    changed_files=$(get_changed_files "$merge_base" "$file_pattern")
    temp_file=$(make_temp_file)
    calculate_coverage "$changed_files" "$temp_file"
    check_coverage_data_presence "$changed_files" "$temp_file"
    coverage_percentage=$(extract_coverage_percentage "$temp_file")
    check_coverage_result "$temp_file" "$coverage_percentage" "$MIN_COVERAGE"
}

check_diff_coverage "$BASE_BRANCH" "$FILE_PATTERN" "$MIN_COVERAGE"
