#!/usr/bin/env bash
set -e

echo ""
echo "🐳 Running PHP Quality Checks (Docker Container Mode)"
echo "===================================================="

PROJECT_DIR="/project"
TOOLKIT_DIR="/project/vendor/voyager/php-quality-tools/configs"

echo "📂 Project directory: $PROJECT_DIR"
echo "🧰 Toolkit directory: $TOOLKIT_DIR"

# Check container environment
if [ ! -f "/.dockerenv" ] && [ -z "$DOCKER_CONTAINER" ]; then
  echo "⚠️  This script is designed to run inside a Docker container"
  echo "   Use run-quality-checks.sh for local execution or setup-docker-hooks.sh for git integration"
fi

cd "$PROJECT_DIR"

# ------------------------------
# Detect directories to scan
# ------------------------------
SCAN_DIRS=""
if [ -n "$1" ]; then
  IFS=',' read -ra COMMON_DIRS <<< "$1"
  echo "🔧 Using custom directories from argument: ${COMMON_DIRS[*]}"
else
  COMMON_DIRS=("src" "app" "lib" "tests" "test")
  echo "🔍 Auto-detecting directories from defaults: ${COMMON_DIRS[*]}"
fi

for dir in "${COMMON_DIRS[@]}"; do
  dir=$(echo "$dir" | xargs)
  if [ -d "$PROJECT_DIR/$dir" ]; then
    SCAN_DIRS="$SCAN_DIRS $dir"
  fi
done

if [ -z "$SCAN_DIRS" ]; then
  echo "⚠️  No specified directories found, searching for PHP files..."
  for test_dir in src app lib tests test public www; do
    if [ -d "$PROJECT_DIR/$test_dir" ] && find "$PROJECT_DIR/$test_dir" -name "*.php" -print -quit | grep -q .; then
      SCAN_DIRS="$SCAN_DIRS $test_dir"
    fi
  done

  if [ -z "$SCAN_DIRS" ]; then
    echo "❌ No PHP files found to analyze"
    echo "✅ All quality checks completed!"
    exit 0
  fi
fi

echo "🎯 Scanning directories:$SCAN_DIRS"
echo ""

# ------------------------------
# Ensure vendor binaries exist
# ------------------------------
if [ ! -f "$PROJECT_DIR/vendor/bin/phpcs" ]; then
  echo "⚠️  vendor/bin/phpcs not found — did you run 'composer install'?"
  exit 1
fi

# ------------------------------
# Determine which configs to use
# ------------------------------
if [ -f "$PROJECT_DIR/phpcs.xml" ]; then
  PHPCS_CONFIG="./phpcs.xml"
else
  PHPCS_CONFIG="$TOOLKIT_DIR/phpcs.xml"
fi

if [ -f "$PROJECT_DIR/phpstan.neon" ]; then
  PHPSTAN_CONFIG="./phpstan.neon"
else
  PHPSTAN_CONFIG="$TOOLKIT_DIR/phpstan.neon"
fi

if [ -f "$PROJECT_DIR/grumphp.yml" ]; then
  GRUMPHP_CONFIG="./grumphp.yml"
else
  GRUMPHP_CONFIG="$TOOLKIT_DIR/grumphp.yml"
fi

echo "⚙️  Config selection:"
echo "   • PHP_CodeSniffer: $PHPCS_CONFIG"
echo "   • PHPStan:         $PHPSTAN_CONFIG"
echo "   • GrumPHP:         $GRUMPHP_CONFIG"
echo ""

# ------------------------------
# 1️⃣ Run PHP_CodeSniffer
# ------------------------------
echo "🔹 Running PHP_CodeSniffer..."
vendor/bin/phpcs --standard="$PHPCS_CONFIG" $SCAN_DIRS || PHPCS_FAILED=1
echo ""

# ------------------------------
# 2️⃣ Run PHPStan
# ------------------------------
echo "🔹 Running PHPStan..."
vendor/bin/phpstan analyse --configuration="$PHPSTAN_CONFIG" $SCAN_DIRS || PHPSTAN_FAILED=1
echo ""

# ------------------------------
# 3️⃣ Run GrumPHP (optional)
# ------------------------------
if [ "$2" = "--with-grumphp" ] && [ -f "$PROJECT_DIR/vendor/bin/grumphp" ]; then
  echo "🔹 Running GrumPHP..."
  vendor/bin/grumphp run --config="$GRUMPHP_CONFIG" || GRUMPHP_FAILED=1
  echo ""
fi

# ------------------------------
# Summary
# ------------------------------
if [ "$PHPCS_FAILED" = "1" ] || [ "$PHPSTAN_FAILED" = "1" ] || [ "$GRUMPHP_FAILED" = "1" ]; then
  echo "❌ Quality checks failed!"
  echo "------------------------------------"
  exit 1
else
  echo "✅ All quality checks passed!"
  echo "------------------------------------"
fi
