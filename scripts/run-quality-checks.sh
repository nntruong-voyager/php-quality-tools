#!/usr/bin/env bash
set -e

echo ""
echo "🐳 Running PHP Quality Checks (Docker Container Mode)"
echo "===================================================="

# This script is designed to run INSIDE the Docker container
# Path to project root (mounted as /project in container)
PROJECT_DIR="/project"
TOOLKIT_DIR="/project/vendor/voyager/php-quality-tools/configs"

echo "📂 Project directory: $PROJECT_DIR"
echo "🧰 Toolkit directory: $TOOLKIT_DIR"

# Check if we're actually inside a container
if [ ! -f "/.dockerenv" ] && [ -z "$DOCKER_CONTAINER" ]; then
  echo "⚠️  This script is designed to run inside a Docker container"
  echo "   Use run-quality-checks.sh for local execution or setup-docker-hooks.sh for git integration"
fi

cd "$PROJECT_DIR"

# Auto-detect directories to scan (same logic as main script)
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
    echo "❌ No PHP files found to analyze"
    echo "✅ All quality checks completed!"
    exit 0
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
vendor/bin/phpcs --standard="$TOOLKIT_DIR/phpcs.xml" $SCAN_DIRS || PHPCS_FAILED=1
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
vendor/bin/phpstan analyse --configuration="$CONFIG_FILE" $SCAN_DIRS || PHPSTAN_FAILED=1
echo ""

# 3️⃣ Run GrumPHP (if specifically requested)
if [ "$2" = "--with-grumphp" ] && [ -f "$PROJECT_DIR/vendor/bin/grumphp" ]; then
  echo "🔹 Running GrumPHP..."
  vendor/bin/grumphp run --config="$TOOLKIT_DIR/grumphp.yml" || GRUMPHP_FAILED=1
  echo ""
fi

# Report results
if [ "$PHPCS_FAILED" = "1" ] || [ "$PHPSTAN_FAILED" = "1" ] || [ "$GRUMPHP_FAILED" = "1" ]; then
  echo "❌ Quality checks failed!"
  echo "------------------------------------"
  exit 1
else
  echo "✅ All quality checks passed!"
  echo "------------------------------------"
fi
