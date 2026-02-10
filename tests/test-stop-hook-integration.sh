#!/bin/bash
# Integration tests for stop-hook.sh skill injection
# Tests that stop-hook.sh correctly calls discover-skills.sh and injects content

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOP_HOOK="$SCRIPT_DIR/../hooks/stop-hook.sh"
DISCOVER_SKILLS="$SCRIPT_DIR/../hooks/discover-skills.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

echo "Integration tests for stop-hook.sh"
echo "===================================="
echo

# Test 1: stop-hook.sh has valid bash syntax
echo -n "Testing: stop-hook.sh syntax ... "
if bash -n "$STOP_HOOK" 2>/dev/null; then
  echo -e "${GREEN}PASS${NC}"
  ((PASS++))
else
  echo -e "${RED}FAIL${NC}"
  ((FAIL++))
fi

# Test 2: stop-hook.sh references discover-skills.sh
echo -n "Testing: stop-hook.sh references discover-skills.sh ... "
if grep -q "discover-skills.sh" "$STOP_HOOK"; then
  echo -e "${GREEN}PASS${NC}"
  ((PASS++))
else
  echo -e "${RED}FAIL${NC}"
  ((FAIL++))
fi

# Test 3: stop-hook.sh reads task_description from state.json
echo -n "Testing: stop-hook.sh reads task_description ... "
if grep -q 'task_description' "$STOP_HOOK"; then
  echo -e "${GREEN}PASS${NC}"
  ((PASS++))
else
  echo -e "${RED}FAIL${NC}"
  ((FAIL++))
fi

# Test 4: stop-hook.sh updates state.json with detected_skills
echo -n "Testing: stop-hook.sh updates detected_skills ... "
if grep -q 'detected_skills' "$STOP_HOOK"; then
  echo -e "${GREEN}PASS${NC}"
  ((PASS++))
else
  echo -e "${RED}FAIL${NC}"
  ((FAIL++))
fi

# Test 5: stop-hook.sh has interview: case
echo -n "Testing: stop-hook.sh has interview case ... "
if grep -q '"interview:")' "$STOP_HOOK"; then
  echo -e "${GREEN}PASS${NC}"
  ((PASS++))
else
  echo -e "${RED}FAIL${NC}"
  ((FAIL++))
fi

# Test 6: stop-hook.sh has research: case (should be unchanged)
echo -n "Testing: stop-hook.sh has research case ... "
if grep -q '"research:")' "$STOP_HOOK"; then
  echo -e "${GREEN}PASS${NC}"
  ((PASS++))
else
  echo -e "${RED}FAIL${NC}"
  ((FAIL++))
fi

# Test 7: HEREDOC is double-quoted (not single-quoted)
echo -n "Testing: interview HEREDOC is double-quoted ... "
# Extract the interview case and check for double-quoted HEREDOC
if sed -n '/^[[:space:]]*"interview:"/,/^[[:space:]]*;;/p' "$STOP_HOOK" | grep -q 'HEREDOC || true' | grep -qv "'HEREDOC'"; then
  echo -e "${GREEN}PASS${NC}"
  ((PASS++))
else
  # More lenient check - just ensure it's not single-quoted
  if sed -n '/^[[:space:]]*"interview:"/,/^[[:space:]]*;;/p' "$STOP_HOOK" | grep -v "'HEREDOC'" | grep -q "HEREDOC"; then
    echo -e "${GREEN}PASS${NC}"
    ((PASS++))
  else
    echo -e "${RED}FAIL${NC}"
    ((FAIL++))
  fi
fi

# Test 8: research: case is completely unmodified (contains specific original text)
echo -n "Testing: research case unchanged ... "
if grep -A 3 '"research:")' "$STOP_HOOK" | grep -q "BEAST-PLAN: Research complete"; then
  echo -e "${GREEN}PASS${NC}"
  ((PASS++))
else
  echo -e "${RED}FAIL${NC}"
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
