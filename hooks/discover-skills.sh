#!/bin/bash
# Dynamic skill discovery for beast-plan
# Finds skills by matching keywords in YAML frontmatter descriptions
# Returns JSON array of top 3 matches: [{name, path, score}]
set -euo pipefail

TASK_DESC="${1:-}"
SEARCH_ROOT="${SKILL_SEARCH_ROOT:-$HOME/.claude}"
MAX_RESULTS=3

# Stop words to filter out (common words that don't indicate skill relevance)
STOP_WORDS="a an the is are was were be been being have has had do does did will would shall should may might can could of in to for on with at by from as into through during before after above below between under again further then once here there when where why how all each every both few more most other some such no nor not only own same so than too very just"

# Fail-safe: return empty array on any error
trap 'echo "[]"; exit 0' ERR

# Return empty array if no task description
if [[ -z "$TASK_DESC" ]]; then
  echo "[]"
  exit 0
fi

# Extract keywords from task description
# 1. Convert to lowercase
# 2. Remove punctuation
# 3. Split into words
# 4. Filter out stop words
# 5. Keep unique words
extract_keywords() {
  local text="$1"
  local keywords=""

  # Lowercase and remove punctuation
  text=$(echo "$text" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' ' ')

  # Split into words and filter
  for word in $text; do
    # Skip short words (< 3 chars) and stop words
    if [[ ${#word} -lt 3 ]]; then
      continue
    fi

    # Check if word is a stop word
    local is_stop=0
    for stop in $STOP_WORDS; do
      if [[ "$word" == "$stop" ]]; then
        is_stop=1
        break
      fi
    done

    if [[ $is_stop -eq 0 ]]; then
      # Add to keywords if not already present
      if ! echo "$keywords" | grep -qw "$word"; then
        keywords="$keywords $word"
      fi
    fi
  done

  echo "$keywords"
}

# Find all SKILL.md files under ~/.claude
find_skill_files() {
  # Find all SKILL.md files in skills directories
  # Pattern: ~/.claude/**/skills/*/SKILL.md
  find "$SEARCH_ROOT" -type f -path "*/skills/*/SKILL.md" 2>/dev/null || true
}

# Parse YAML frontmatter from SKILL.md and extract name/description
parse_skill_metadata() {
  local file="$1"
  local in_frontmatter=0
  local name=""
  local desc=""

  while IFS= read -r line; do
    # Detect start of frontmatter
    if [[ "$line" == "---" ]]; then
      if [[ $in_frontmatter -eq 0 ]]; then
        in_frontmatter=1
        continue
      else
        # End of frontmatter
        break
      fi
    fi

    if [[ $in_frontmatter -eq 1 ]]; then
      # Extract name
      if [[ "$line" =~ ^name:\ *(.+)$ ]]; then
        name="${BASH_REMATCH[1]}"
      fi
      # Extract description
      if [[ "$line" =~ ^description:\ *(.+)$ ]]; then
        desc="${BASH_REMATCH[1]}"
      fi
    fi
  done < "$file"

  echo "$name|$desc"
}

# Score a skill based on keyword matches in description
score_skill() {
  local desc="$1"
  local keywords="$2"
  local score=0

  # Convert description to lowercase for matching
  desc=$(echo "$desc" | tr '[:upper:]' '[:lower:]')

  # Count keyword matches
  for keyword in $keywords; do
    # Use grep -o to count occurrences
    local count=$(echo "$desc" | grep -o "$keyword" | wc -l | tr -d ' ')
    score=$((score + count))
  done

  echo "$score"
}

# Main execution
KEYWORDS=$(extract_keywords "$TASK_DESC")

# If no keywords extracted, return empty array
if [[ -z "$KEYWORDS" ]]; then
  echo "[]"
  exit 0
fi

# Find and score all skills
SCORED=""
SEEN_NAMES=""

# Use temp file for deduplication (bash 3.2 doesn't have associative arrays)
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"; echo "[]"; exit 0' ERR

# Collect all skills first, then process
while IFS= read -r skill_file; do
  # Parse metadata
  metadata=$(parse_skill_metadata "$skill_file")
  name=$(echo "$metadata" | cut -d'|' -f1)
  desc=$(echo "$metadata" | cut -d'|' -f2)

  # Skip if no name
  if [[ -z "$name" ]]; then
    continue
  fi

  # Store in temp file: name|desc|path
  echo "$name|$desc|$skill_file" >> "$TEMP_FILE"
done < <(find_skill_files)

# Deduplicate by name (keep first occurrence) and score
# Sort by name, use uniq to keep first, then score
while IFS='|' read -r name desc skill_file; do
  # Score this skill
  score=$(score_skill "$desc" "$KEYWORDS")

  # Only include skills with score > 0
  if [[ $score -gt 0 ]]; then
    SCORED="$SCORED$score	$name	$skill_file
"
  fi
done < <(sort -t'|' -k1,1 -u "$TEMP_FILE")

# Clean up temp file
rm -f "$TEMP_FILE"

# If no matches, return empty array
if [[ -z "$SCORED" ]]; then
  echo "[]"
  exit 0
fi

# Sort by score (descending), take top N, format as JSON
# FIX (Skeptic Mirage 1): Filter out empty lines before JSON generation
echo "$SCORED" | grep -v '^$' | sort -t$'	' -k1 -nr | head -n "$MAX_RESULTS" | awk -F'	' '
BEGIN {
  printf "["
  first = 1
}
{
  if (!first) printf ","
  first = 0
  # Escape double quotes and backslashes in strings for JSON
  gsub(/"/, "\\\"", $2)
  gsub(/\\/, "\\\\", $2)
  gsub(/"/, "\\\"", $3)
  gsub(/\\/, "\\\\", $3)
  printf "\n  {\"name\": \"%s\", \"path\": \"%s\", \"score\": %d}", $2, $3, $1
}
END {
  if (!first) printf "\n"
  printf "]\n"
}'

exit 0
