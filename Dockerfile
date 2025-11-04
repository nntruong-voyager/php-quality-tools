FROM php:8.2-cli
LABEL maintainer="nntruong-voyager"

RUN apt-get update && apt-get install -y --no-install-recommends     git unzip zip libzip-dev libpng-dev libonig-dev ca-certificates     && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install pdo pdo_mysql || true

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app
ENV PATH="/app/vendor/bin:${PATH}"
CMD ["tail", "-f", "/dev/null"]
