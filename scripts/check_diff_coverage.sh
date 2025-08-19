#!/bin/bash
set -euo pipefail

MIN_COVERAGE=100
FILE_PATTERN="provider"
BASE_BRANCH="master"

debug_print() {
  printf "[DEBUG] %s\n" "$*" >&2
}

print_error() {
    red_color="\e[31;1m%s\e[0m\n"
    printf "${red_color}" "$1">&2
}

print_success() {
    green_color="\e[32;1m%s\e[0m\n"
    printf "${green_color}" "$1">&2
}

raise_error() {
    print_error "$1"
    exit 1
}


check_prerequisites() {
    local missing_tools
    missing_tools=()
    
    command -v git >/dev/null 2>&1 || missing_tools+=("git")
    command -v lcov >/dev/null 2>&1 || missing_tools+=("lcov")
    command -v bc >/dev/null 2>&1 || missing_tools+=("bc")
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        local tools_list
        tools_list=$(printf ", %s" "${missing_tools[@]}")
        tools_list=${tools_list:2}  # Remove leading ", "
        raise_error "Missing required tools: ${tools_list}. Please install them first."
    fi
}

check_coverage_file_presence() {
  if [ ! -f "coverage/lcov.info" ]; then
    raise_error "Coverage file not found. Run 'flutter test --coverage' first."
  fi
}

fetch_base_branch() {
    local base_branch
    base_branch=$1
    printf "Fetching latest ${base_branch}...\n"
    git fetch --no-tags --prune origin +refs/heads/${base_branch}:refs/remotes/origin/${base_branch}
}

get_merge_base() {
    local base_branch
    base_branch=$1
    merge_base=$(git merge-base HEAD "origin/${base_branch}" 2>/dev/null || git merge-base HEAD "${base_branch}" 2>/dev/null || echo "")
    echo "$merge_base"
}

check_merge_base() {
    local base_branch
    base_branch=$1
    local merge_base
    merge_base=$2
    if [ -z "$merge_base" ]; then
        raise_error "Could not find common ancestor with ${base_branch}. Ensure the branch exists and has shared history."
    fi
}

get_lib_file_from_test_file() {
    local test_file
    test_file=$1
    local lib_file
    lib_file=${test_file/test\//lib\/}
    lib_file=${lib_file%_test.dart}
    lib_file=${lib_file}.dart
    echo "$lib_file"
}

get_lib_files_from_test_files() {
    local test_changed_files
    test_changed_files=$1
    local lib_files_from_test_files
    lib_files_from_test_files=""
    for test_file in $test_changed_files; do
        lib_file=$(get_lib_file_from_test_file "$test_file")
        if [ -n "$lib_files_from_test_files" ]; then
            lib_files_from_test_files="$lib_files_from_test_files"$'\n'"$lib_file"
        else
            lib_files_from_test_files="$lib_file"
        fi
    done
    echo "$lib_files_from_test_files"
}

combine_changed_files() {
    local lib_changed_files
    lib_changed_files=$1
    local lib_files_from_test_files
    lib_files_from_test_files=$2
    local changed_files
    if [ -n "$lib_changed_files" ] && [ -n "$lib_files_from_test_files" ]; then
        changed_files=$(printf "%s\n%s" "$lib_changed_files" "$lib_files_from_test_files" | sort -u)
    elif [ -n "$lib_changed_files" ]; then
        changed_files="$lib_changed_files"
    elif [ -n "$lib_files_from_test_files" ]; then
        changed_files="$lib_files_from_test_files"
    else
        changed_files=""
    fi
    echo "$changed_files"
}

get_files_to_check() {
    local merge_base
    merge_base=$1
    local file_pattern
    file_pattern=$2
    local diff_files
    diff_files=$(git diff --name-only "$merge_base" HEAD | grep "${file_pattern}")
    lib_diff_files=$(echo "$diff_files" | grep '^lib/.*\.dart$' || true)
    test_diff_files=$(echo "$diff_files" | grep '^test/.*\.dart$' || true)
    lib_files_from_test_diff_files=$(get_lib_files_from_test_files "$test_diff_files")
    local files_to_check
    files_to_check=$(combine_changed_files "$lib_diff_files" "$lib_files_from_test_diff_files")

    if [ -z "$files_to_check" ]; then
       print_success "No lib/ or test/ Dart files matching '${file_pattern}' changed. Skipping coverage check."
       exit 0
    fi
    echo "$files_to_check"
}

make_temp_file() {
    mktemp
}

calculate_coverage() {
    local files_to_check
    files_to_check=$1
    local temp_lcov
    temp_lcov=$2
    local -a files_array
    while IFS= read -r file; do
        files_array+=("$file")
    done <<< "$files_to_check"
    lcov --extract coverage/lcov.info "${files_array[@]}" --output-file "$temp_lcov"
}

extract_coverage_percentage() {
    local temp_lcov
    temp_lcov=$1
    local coverage_percentage
    coverage_percentage="0"
    local total_lines hit_lines
    total_lines=$(grep "^LF:" "$temp_lcov" | awk -F: '{sum += $2} END {print sum}' || echo "0")
    hit_lines=$(grep "^LH:" "$temp_lcov" | awk -F: '{sum += $2} END {print sum}' || echo "0")
    if [ "$total_lines" -gt 0 ]; then
      coverage_percentage=$(echo "scale=1; $hit_lines * 100 / $total_lines" | bc -l)
    fi
    coverage_percentage=$(printf "%.0f" "$coverage_percentage" 2>/dev/null || echo "0")
    echo "$coverage_percentage"
}

print_files_with_low_coverage() {
    local temp_lcov
    temp_lcov=$1
    local min_coverage
    min_coverage=$2
    
    lcov --quiet --list "$temp_lcov" 2>/dev/null | grep -v "Message summary" | grep -E "^[^|]*\|" | grep -v "Total:" | grep -v "Filename" | grep -v "====" | grep "\.dart" | while IFS='|' read -r file coverage rest; do
        file_coverage=$(echo "$coverage" | sed 's/^[[:space:]]*\([0-9.]*\)%.*/\1/')
        if [[ "$file_coverage" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            if [ "$(echo "$file_coverage < $min_coverage" | bc -l)" = "1" ]; then
                print_error "  - $file"
            else
                print_success "  - $file"
            fi
        fi
    done
}

handle_coverage_failure() {
    local temp_lcov
    temp_lcov=$1
    local coverage_percentage
    coverage_percentage=$2
    local min_coverage
    min_coverage=$3
    print_error "Oops! Coverage ${coverage_percentage}% < ${min_coverage}% for changed files"
    print_error "Check the coverage report for these files:"
    print_files_with_low_coverage "$temp_lcov" "$min_coverage"
    exit 1
}

check_coverage_result() {
    local temp_lcov
    temp_lcov=$1
    local coverage_percentage
    coverage_percentage=$2
    local min_coverage
    min_coverage=$3
    
    if ! check_coverage_threshold "$coverage_percentage" "$min_coverage"; then
        handle_coverage_failure "$temp_lcov" "$coverage_percentage" "$min_coverage"
    fi

    print_success "Coverage ${coverage_percentage}% ✓" 
}

check_coverage_threshold() {
    local coverage_percentage
    coverage_percentage=$1
    local min_coverage
    min_coverage=$2
    if [ -n "$coverage_percentage" ] && (($(echo "$coverage_percentage >= $min_coverage" | bc -l))); then
        return 0
    else
        return 1
    fi
}


check_diff_coverage() {
    printf "Checking coverage for changed files...\n"
    local base_branch
    base_branch=$1
    local file_pattern
    file_pattern=$2
    local min_coverage
    min_coverage=$3
    local files_to_check
    check_prerequisites
    check_coverage_file_presence
    fetch_base_branch "$base_branch"
    merge_base=$(get_merge_base "$base_branch")
    check_merge_base "$base_branch" "$merge_base"
    files_to_check=$(get_files_to_check "$merge_base" "$file_pattern")
    if [ -z "$files_to_check" ]; then
       exit 0
    else
        temp_file=$(make_temp_file)
        trap "rm -f $temp_file" EXIT
        calculate_coverage "$files_to_check" "$temp_file"
        coverage_percentage=$(extract_coverage_percentage "$temp_file")
        check_coverage_result "$temp_file" "$coverage_percentage" "$min_coverage"
    fi
}

check_diff_coverage "$BASE_BRANCH" "$FILE_PATTERN" "$MIN_COVERAGE"
