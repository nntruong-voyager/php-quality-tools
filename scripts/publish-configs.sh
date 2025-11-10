#!/bin/bash
set -e

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../configs" && pwd)"
TARGET_DIR="$(pwd)"

echo "🚀 Publishing config files to project root..."

for file in "$SOURCE_DIR"/*; do
  filename=$(basename "$file")
  target="$TARGET_DIR/$filename"

  if [ -f "$target" ]; then
    echo "⚠️  $filename already exists — skipped."
  else
    cp "$file" "$target"
    echo "✅ Published: $filename"
  fi
done

echo
echo "🎉 Done. You can now edit the config files directly in your project root."
