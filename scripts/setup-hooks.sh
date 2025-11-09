#!/usr/bin/env bash
set -e

echo ""
echo "🐳 Setting up Git Hooks for PHP Quality Tools"
echo "=========================================================="

# Path to project root (where this script is executed)
PROJECT_DIR=$(pwd)

echo "📂 Project directory: $PROJECT_DIR"

# Check if docker-compose file exists
if [ ! -f "$PROJECT_DIR/docker-compose.override.yml" ] && [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
  echo "❌ No docker-compose.yml or docker-compose.override.yml found in project root"
  echo "   Please ensure you have the php-quality-tools service configured in your docker-compose setup"
  exit 1
fi

# Install GrumPHP hooks that will execute inside Docker
echo "🔧 Installing GrumPHP git hooks..."

# Create a custom pre-commit hook that runs inside Docker
GIT_HOOKS_DIR="$PROJECT_DIR/.git/hooks"
PRE_COMMIT_HOOK="$GIT_HOOKS_DIR/pre-commit"

# Ensure hooks directory exists
mkdir -p "$GIT_HOOKS_DIR"

# Voyager hook identifier
VOYAGER_HOOK_MARKER="# Auto-generated pre-commit hook for Voyager PHP Quality Tools"

# If pre-commit exists and is not our Voyager hook, back it up and append our hook
if [ -f "$PRE_COMMIT_HOOK" ]; then
  if ! grep -q "$VOYAGER_HOOK_MARKER" "$PRE_COMMIT_HOOK"; then
    BACKUP_HOOK="$PRE_COMMIT_HOOK.backup.$(date +%s)"
    echo "⚠️  Existing pre-commit hook detected. Backing up to $BACKUP_HOOK and appending Voyager hook."
    mv "$PRE_COMMIT_HOOK" "$BACKUP_HOOK"
    # Create a new pre-commit hook that runs both the backup and Voyager logic
    echo "#!/bin/bash" > "$PRE_COMMIT_HOOK"
    echo "# Combined pre-commit hook: original backed up, Voyager hook appended" >> "$PRE_COMMIT_HOOK"
    echo "# --- Original pre-commit hook ---" >> "$PRE_COMMIT_HOOK"
    cat "$BACKUP_HOOK" >> "$PRE_COMMIT_HOOK"
    echo "# --- Voyager PHP Quality Tools hook ---" >> "$PRE_COMMIT_HOOK"
    cat << 'EOF' >> "$PRE_COMMIT_HOOK"
$VOYAGER_HOOK_MARKER
set -e

echo "🐳 Running PHP Quality Checks in Docker container..."

# Check if php-quality-tools container is running
if ! docker compose ps php-quality-tools 2>/dev/null | grep -q "running" && ! docker-compose ps php-quality-tools 2>/dev/null | grep -q "Up"; then
    echo "❌ php-quality-tools container is not running"
    echo "   Please start it with: docker compose up -d php-quality-tools"
    exit 1
fi

# Run GrumPHP inside the Docker container
if command -v "docker compose" &> /dev/null; then
    docker compose exec -T php-quality-tools bash -c "cd /project && vendor/bin/grumphp run --config=vendor/voyager/php-quality-tools/configs/grumphp.yml"
else
    docker-compose exec -T php-quality-tools bash -c "cd /project && vendor/bin/grumphp run --config=vendor/voyager/php-quality-tools/configs/grumphp.yml"
fi
EOF
    chmod +x "$PRE_COMMIT_HOOK"
  else
    echo "ℹ️  Voyager pre-commit hook already installed. Updating to latest version."
    # Overwrite with latest Voyager hook
    cat > "$PRE_COMMIT_HOOK" << 'EOF'
#!/bin/bash
# Auto-generated pre-commit hook for Voyager PHP Quality Tools
# This runs quality checks inside the php-quality-tools Docker container

set -e

echo "🐳 Running PHP Quality Checks in Docker container..."

# Check if php-quality-tools container is running
if ! docker compose ps php-quality-tools 2>/dev/null | grep -q "running" && ! docker-compose ps php-quality-tools 2>/dev/null | grep -q "Up"; then
    echo "❌ php-quality-tools container is not running"
    echo "   Please start it with: docker compose up -d php-quality-tools"
    exit 1
fi

# Run GrumPHP inside the Docker container
if command -v "docker compose" &> /dev/null; then
    docker compose exec -T php-quality-tools bash -c "cd /project && vendor/bin/grumphp run --config=vendor/voyager/php-quality-tools/configs/grumphp.yml"
else
    docker-compose exec -T php-quality-tools bash -c "cd /project && vendor/bin/grumphp run --config=vendor/voyager/php-quality-tools/configs/grumphp.yml"
fi
EOF
    chmod +x "$PRE_COMMIT_HOOK"
  fi
else
  # No pre-commit hook exists, create Voyager hook
  cat > "$PRE_COMMIT_HOOK" << 'EOF'
#!/bin/bash
# Auto-generated pre-commit hook for Voyager PHP Quality Tools
# This runs quality checks inside the php-quality-tools Docker container

set -e

echo "🐳 Running PHP Quality Checks in Docker container..."

# Check if php-quality-tools container is running
if ! docker compose ps php-quality-tools 2>/dev/null | grep -q "running" && ! docker-compose ps php-quality-tools 2>/dev/null | grep -q "Up"; then
    echo "❌ php-quality-tools container is not running"
    echo "   Please start it with: docker compose up -d php-quality-tools"
    exit 1
fi

# Run GrumPHP inside the Docker container
if command -v "docker compose" &> /dev/null; then
    docker compose exec -T php-quality-tools bash -c "cd /project && vendor/bin/grumphp run --config=vendor/voyager/php-quality-tools/configs/grumphp.yml"
else
    docker-compose exec -T php-quality-tools bash -c "cd /project && vendor/bin/grumphp run --config=vendor/voyager/php-quality-tools/configs/grumphp.yml"
fi
EOF
  chmod +x "$PRE_COMMIT_HOOK"
fi

echo "✅ Git pre-commit hook installed successfully!"
echo ""
echo "🎯 Setup Complete!"
echo ""
echo "🚀 Next steps:"
echo "1. Make sure php-quality-tools container is running: docker compose up -d php-quality-tools"
echo "2. Try making a commit to test the setup"
echo ""
echo "💡 To disable hooks temporarily: git commit --no-verify"
echo "💡 To remove hooks: rm .git/hooks/pre-commit"
echo ""
