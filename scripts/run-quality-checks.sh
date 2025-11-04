#!/usr/bin/env bash
set -e

echo ""
echo "🚀 Running Voyager PHP Quality Checks"
echo "===================================="

# Base directory for the toolkit (this repo, inside vendor)
TOOLKIT_DIR="$(dirname "$0")/../configs"

# Path to project root (where this script is executed)
PROJECT_DIR=$(pwd)

echo "📂 Project directory: $PROJECT_DIR"
echo "🧰 Toolkit directory: $TOOLKIT_DIR"
echo ""

# Ensure vendor binaries exist
if [ ! -f "$PROJECT_DIR/vendor/bin/phpcs" ]; then
  echo "⚠️  vendor/bin/phpcs not found — did you run 'composer install'?"
  exit 1
fi

# 1️⃣ Run PHP_CodeSniffer
echo "🔹 Running PHP_CodeSniffer..."
$PROJECT_DIR/vendor/bin/phpcs --standard="$TOOLKIT_DIR/phpcs.xml" "$PROJECT_DIR/src" "$PROJECT_DIR/tests" || true
echo ""

# 2️⃣ Run PHPStan
echo "🔹 Running PHPStan..."
# Determine which config to use
if [ -f "$PROJECT_DIR/phpstan.neon" ]; then
  CONFIG_FILE="$PROJECT_DIR/phpstan.neon"
else
  CONFIG_FILE="$TOOLKIT_DIR/phpstan.neon"
fi
echo "PHPStan CONFIG_FILE: $CONFIG_FILE"
# Run PHPStan from the project root so relative paths work correctly
(
  cd "$PROJECT_DIR"
  echo "Current directory: $(pwd)"
  vendor/bin/phpstan analyse --configuration="$CONFIG_FILE" src tests || true
)
echo ""

# 3️⃣ Run GrumPHP (pre-commit checks)
if [ -f "$PROJECT_DIR/vendor/bin/grumphp" ]; then
  echo "🔹 Running GrumPHP..."
  $PROJECT_DIR/vendor/bin/grumphp run || true
  echo ""
fi

echo "✅ All quality checks completed!"
echo "------------------------------------"
