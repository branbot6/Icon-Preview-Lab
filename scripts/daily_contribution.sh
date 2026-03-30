#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATE_INPUT="${1:-}"
DATE_VALUE="${DATE_INPUT:-$(date +%F)}"
DAILY_DIR="$ROOT_DIR/logs/daily"
DAILY_FILE="$DAILY_DIR/$DATE_VALUE.md"

mkdir -p "$DAILY_DIR"

if [[ ! -f "$DAILY_FILE" ]]; then
  cat > "$DAILY_FILE" <<EOT
# Daily Log - $DATE_VALUE

## Goal
- 

## Change
- 

## Verification
- [ ] swift build
- [ ] manual app smoke check

## Notes
- 

## Next
- 
EOT
  echo "Created: $DAILY_FILE"
else
  echo "Exists: $DAILY_FILE"
fi

echo
echo "Next steps:"
echo "1) Fill the daily log with the real change you made."
echo "2) Make one small code or docs improvement."
echo "3) Run verification (for example: swift build)."
echo "4) Commit your work."
echo
echo "Suggested commands:"
echo "  ${EDITOR:-vi} \"$DAILY_FILE\""
echo "  git add \"$DAILY_FILE\""
echo "  git commit -m \"docs(daily): $DATE_VALUE progress\""
