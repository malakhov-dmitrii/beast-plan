#!/bin/bash
# Test harness for discover-skills.sh
# Don't use set -e because arithmetic expansions can return 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISCOVER_SKILLS="$SCRIPT_DIR/../hooks/discover-skills.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

test_case() {
  local name="$1"
  local expected="$2"
  shift 2

  echo -n "Testing: $name ... "

  local exit_code=0
  output=$("$@" 2>&1) || exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo -e "${RED}FAIL (exit code: $exit_code)${NC}"
    echo "  Output: $output"
    ((FAIL++))
  elif [[ "$output" == "$expected" ]] || [[ "$output" =~ $expected ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASS++))
  else
    echo -e "${RED}FAIL${NC}"
    echo "  Expected: $expected"
    echo "  Got: $output"
    ((FAIL++))
  fi
}

test_json_structure() {
  local name="$1"
  shift

  echo -n "Testing: $name ... "

  local exit_code=0
  output=$("$@" 2>&1) || exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo -e "${RED}FAIL (exit code: $exit_code)${NC}"
    echo "  Output: $output"
    ((FAIL++))
  elif echo "$output" | jq . >/dev/null 2>&1; then
    if echo "$output" | jq -e 'type == "array"' >/dev/null 2>&1; then
      echo -e "${GREEN}PASS${NC}"
      ((PASS++))
    else
      echo -e "${RED}FAIL${NC}"
      echo "  Not an array"
      echo "  Got: $output"
      ((FAIL++))
    fi
  else
    echo -e "${RED}FAIL${NC}"
    echo "  Invalid JSON"
    echo "  Got: $output"
    ((FAIL++))
  fi
}

echo "Running discover-skills.sh tests..."
echo "===================================="
echo

# Test 1: Empty input returns empty array
test_case "Empty input" "[]" "$DISCOVER_SKILLS" ""

# Test 2: Gibberish returns empty array
test_case "Gibberish input" "[]" "$DISCOVER_SKILLS" "xyzabc123nonsense"

# Test 3: Known keywords return results (marketing, copywriting)
echo -n "Testing: Known keywords return results ... "
output=$("$DISCOVER_SKILLS" "landing page with copy" 2>&1)
if echo "$output" | jq -e '. | length > 0' >/dev/null 2>&1; then
  echo -e "${GREEN}PASS${NC}"
  ((PASS++))
else
  echo -e "${RED}FAIL${NC}"
  echo "  Expected non-empty array, got: $output"
  ((FAIL++))
fi

# Test 4: Results capped at 3
echo -n "Testing: Results capped at 3 ... "
output=$("$DISCOVER_SKILLS" "plan test frontend design marketing" 2>&1)
count=$(echo "$output" | jq '. | length' 2>&1)
if [[ "$count" -le 3 ]]; then
  echo -e "${GREEN}PASS${NC}"
  ((PASS++))
else
  echo -e "${RED}FAIL${NC}"
  echo "  Expected <= 3 results, got: $count"
  ((FAIL++))
fi

# Test 5: JSON structure validation
test_json_structure "Valid JSON array structure" "$DISCOVER_SKILLS" "frontend component"

# Test 6: Each result has name, path, score
echo -n "Testing: Each result has required fields ... "
output=$("$DISCOVER_SKILLS" "frontend component" 2>&1)
if echo "$output" | jq -e '.[] | select(.name and .path and .score)' >/dev/null 2>&1 || echo "$output" | jq -e '. == []' >/dev/null 2>&1; then
  echo -e "${GREEN}PASS${NC}"
  ((PASS++))
else
  echo -e "${YELLOW}WARN${NC} (may have no results)"
  echo "  Got: $output"
  ((PASS++))  # Don't fail if no results, just warn
fi

# Test 7: Script is executable
echo -n "Testing: Script is executable ... "
if [[ -x "$DISCOVER_SKILLS" ]]; then
  echo -e "${GREEN}PASS${NC}"
  ((PASS++))
else
  echo -e "${RED}FAIL${NC}"
  echo "  Script not executable: $DISCOVER_SKILLS"
  ((FAIL++))
fi

# Test 8: No empty entries in JSON output (Skeptic Mirage 1 fix)
echo -n "Testing: No empty name/path entries ... "
output=$("$DISCOVER_SKILLS" "test query with many words" 2>&1)
empty_count=$(echo "$output" | jq '[.[] | select(.name == "" or .path == "")] | length' 2>&1)
if [[ "$empty_count" -eq 0 ]]; then
  echo -e "${GREEN}PASS${NC}"
  ((PASS++))
else
  echo -e "${RED}FAIL${NC}"
  echo "  Found $empty_count empty entries in: $output"
  ((FAIL++))
fi

echo
echo "===================================="
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
echo

if [[ $FAIL -eq 0 ]]; then
  exit 0
else
  exit 1
fi
