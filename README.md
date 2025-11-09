# 🧭 Voyager PHP Quality Tools

A **standardized PHP coding quality toolkit** for all company projects.

This repository provides a **unified Docker environment** to analyze, format, and validate code quality consistently — regardless of your local PHP version.

---

## 🚀 Features

- ✅ Unified setup: **PHP_CodeSniffer**, **PHPStan**, **GrumPHP**
- 🐳 **Docker**
- 🔧 Auto Git pre-commit hooks
- 📦 Zero-dependency setup — no need to install PHP locally

---

## ⚙️ Setup Guide

> 💡 Works even if your project doesn’t currently use Docker.
> This service runs separately and doesn’t interfere with your main stack.

---

### 1️⃣ Install via Composer

Add this manually in your project’s `composer.json`:

```jsonc

  "repositories": [
    {
      "type": "vcs",
      "url": "git@github.com:nntruong-voyager/php-quality-tools.git"
    }
  ],
  "require-dev": {
    "voyager/php-quality-tools": "^1.1"
  }

````

Then run:

```bash
composer require --dev voyager/php-quality-tools
```


---

### 2️⃣ Add service to `docker-compose.override.yml`

At the root of your project, create (or append):

```yaml
services:
  php-quality-tools:
    build:
      context: ./vendor/voyager/php-quality-tools
      dockerfile: Dockerfile
    container_name: php-quality-tools
    working_dir: /project
    volumes:
      - .:/project
    command: tail -f /dev/null

```

> 🧩 If your project doesn’t have Docker yet, just place this file —
> you can still run it standalone with `docker compose up`.

---

### 3️⃣ Start the container

```bash
docker compose up -d php-quality-tools
```

---

### 4️⃣ Run code quality checks

```bash
docker-compose exec php-quality-tools bash /project/vendor/voyager/php-quality-tools/scripts/run-quality-checks.sh src,app
```
#### You can add an alias (optional)
```bash
alias phpchecker='docker-compose exec php-quality-tools bash /project/vendor/voyager/php-quality-tools/scripts/run-quality-checks.sh'

phpchecker src,app
```

#### Custom Directory Specification
```bash
# or scan specific directories
docker-compose exec php-quality-tools bash /project/vendor/voyager/php-quality-tools/scripts/run-quality-checks.sh app,src,custom

# Get help
bash docker-compose exec php-quality-tools bash /project/vendor/voyager/php-quality-tools/scripts/run-quality-checks.sh --help
```

---

### 5️⃣ Enable automatic Git checks

#### Runs tools inside Docker container
```bash
docker-compose exec php-quality-tools bash /project/vendor/voyager/php-quality-tools/scripts/setup-hooks.sh
```

This sets up pre-commit hooks so every commit runs the quality checks automatically inside the Docker container. This ensures consistent environment regardless of local PHP version.

---

## 🧰 Tool Overview

| Tool                | Purpose                                          | Config File    |
| ------------------- | ------------------------------------------------ | -------------- |
| **PHP_CodeSniffer** | Code formatting & PSR-12 standard checking       | `phpcs.xml`    |
| **PHPStan**         | Static code analysis & type checking             | `phpstan.neon` |
| **GrumPHP**         | Runs all checks automatically on each Git commit | `grumphp.yml`  |

---
