#!/usr/bin/env bash
set -e

HOOK_DIR=".git/hooks"
HOOK_FILE="$HOOK_DIR/pre-commit"
SOURCE_SNIPPET="vendor/voyager/php-quality-tools/scripts/pre-commit"

echo ""
echo "🔧 Setting up Voyager PHP Quality Tools pre-commit hook..."
echo "---------------------------------------------------------"

# Ensure inside a Git repo
if [ ! -d "$HOOK_DIR" ]; then
  echo "⚠️  No .git directory found. Please run this from your project root after 'git init'."
  exit 0
fi

mkdir -p "$HOOK_DIR"

# If hook exists, check whether it's already integrated
if [ -f "$HOOK_FILE" ]; then
  if grep -q "Voyager PHP Quality Tools" "$HOOK_FILE"; then
    echo "ℹ️  Voyager hook already integrated. Nothing to do."
    exit 0
  fi

  BACKUP_FILE="${HOOK_FILE}.bak_$(date +%s)"
  echo "💾 Existing pre-commit hook found — backing up to $BACKUP_FILE"
  cp "$HOOK_FILE" "$BACKUP_FILE"

  echo "🔗 Appending Voyager quality check to existing hook..."
  cat <<'EOF' >> "$HOOK_FILE"

# --- Voyager PHP Quality Tools Hook ---
echo "🚦 Running Voyager PHP Quality Tools..."
bash vendor/voyager/php-quality-tools/scripts/run-quality-checks.sh
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "❌ Quality checks failed (Voyager). Commit aborted."
  exit 1
fi
# --- End Voyager Hook ---

EOF

else
  echo "🆕 Creating new pre-commit hook..."
  cat <<'EOF' > "$HOOK_FILE"
#!/usr/bin/env bash
set -e

# --- Voyager PHP Quality Tools Hook ---
echo "🚦 Running Voyager PHP Quality Tools..."
bash vendor/voyager/php-quality-tools/scripts/run-quality-checks.sh
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "❌ Quality checks failed (Voyager). Commit aborted."
  exit 1
fi
# --- End Voyager Hook ---

EOF
fi

chmod +x "$HOOK_FILE"

echo "✅ Voyager pre-commit hook installed or updated successfully."
echo "💡 Try committing to see automatic code quality checks!"
echo ""
