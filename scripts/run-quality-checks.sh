#!/usr/bin/env bash
set -e

# Show help if requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "🚀 Voyager PHP Quality Checks"
  echo "============================="
  echo ""
  echo "Usage:"
  echo "  $0 [directories]"
  echo ""
  echo "Arguments:"
  echo "  directories    Comma-separated list of directories to scan (optional)"
  echo ""
  echo "Examples:"
  echo "  $0                      # Auto-detect directories (src, app, lib, tests, test)"
  echo "  $0 src,tests            # Scan only src and tests directories"
  echo "  $0 app,src,custom       # Scan app, src, and custom directories"
  echo "  $0 .                    # Scan current directory"
  echo ""
  echo "If no directories are specified, the script will auto-detect common PHP"
  echo "directories. If none of the specified/default directories exist, it will"
  echo "fall back to scanning the current directory."
  echo ""
  exit 0
fi

echo ""
echo "🚀 Running Voyager PHP Quality Checks"
echo "===================================="

# Base directory for the toolkit (this repo, inside vendor)
TOOLKIT_DIR="$(dirname "$0")/../configs"

# Path to project root (where this script is executed)
PROJECT_DIR=$(pwd)

echo "📂 Project directory: $PROJECT_DIR"
echo "🧰 Toolkit directory: $TOOLKIT_DIR"

# Auto-detect directories to scan
SCAN_DIRS=""

# Check if directories are provided as command line argument
if [ -n "$1" ]; then
  # Parse comma-separated directories from command line
  IFS=',' read -ra COMMON_DIRS <<< "$1"
  echo "🔧 Using custom directories from argument: ${COMMON_DIRS[*]}"
else
  # Default directories to check
  COMMON_DIRS=("src" "app" "lib" "tests" "test")
  echo "🔍 Auto-detecting directories from defaults: ${COMMON_DIRS[*]}"
fi

# Check which directories actually exist
for dir in "${COMMON_DIRS[@]}"; do
  # Trim whitespace from directory name
  dir=$(echo "$dir" | xargs)
  if [ -d "$PROJECT_DIR/$dir" ]; then
    SCAN_DIRS="$SCAN_DIRS $dir"
  fi
done

# If no directories found, try to find PHP files in common locations
if [ -z "$SCAN_DIRS" ]; then
  echo "⚠️  No specified directories found, searching for PHP files..."
  # Try to find directories with PHP files
  FALLBACK_DIRS=""
  for test_dir in src app lib tests test public www; do
    if [ -d "$PROJECT_DIR/$test_dir" ] && find "$PROJECT_DIR/$test_dir" -name "*.php" -print -quit | grep -q .; then
      FALLBACK_DIRS="$FALLBACK_DIRS $test_dir"
    fi
  done
  
  if [ -n "$FALLBACK_DIRS" ]; then
    SCAN_DIRS="$FALLBACK_DIRS"
    echo "📁 Found PHP files in:$FALLBACK_DIRS"
  else
    # Last resort: check if there are any PHP files in root
    if find "$PROJECT_DIR" -maxdepth 1 -name "*.php" -print -quit | grep -q .; then
      SCAN_DIRS="*.php"
      echo "📄 Scanning PHP files in root directory"
    else
      echo "❌ No PHP files found to analyze"
      echo "✅ All quality checks completed!"
      echo "------------------------------------"
      exit 0
    fi
  fi
fi

echo "🎯 Scanning directories:$SCAN_DIRS"
echo ""

# Ensure vendor binaries exist
if [ ! -f "$PROJECT_DIR/vendor/bin/phpcs" ]; then
  echo "⚠️  vendor/bin/phpcs not found — did you run 'composer install'?"
  exit 1
fi

# 1️⃣ Run PHP_CodeSniffer
echo "🔹 Running PHP_CodeSniffer..."
# Use auto-detected directories or let configuration determine paths
(
  cd "$PROJECT_DIR"
  if [ "$SCAN_DIRS" = "*.php" ]; then
    # Scan PHP files in root
    vendor/bin/phpcs --standard="$TOOLKIT_DIR/phpcs.xml" *.php 2>/dev/null || echo "No PHP files found in root directory"
  else
    vendor/bin/phpcs --standard="$TOOLKIT_DIR/phpcs.xml" $SCAN_DIRS || true
  fi
)
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
  # Use auto-detected directories or let configuration file determine paths
  if [ "$SCAN_DIRS" = "*.php" ]; then
    # Scan PHP files in root
    vendor/bin/phpstan analyse --configuration="$CONFIG_FILE" *.php 2>/dev/null || echo "No PHP files found for PHPStan analysis"
  else
    vendor/bin/phpstan analyse --configuration="$CONFIG_FILE" $SCAN_DIRS || true
  fi
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
