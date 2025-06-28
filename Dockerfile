FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    curl \
    libzip-dev \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

COPY --from=composer:2.5 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy composer files first for better caching
COPY composer.json composer.lock ./

# Install dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader --no-scripts

# Copy the rest of the application
COPY . .

# Set proper permissions
RUN chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage \
    && chmod -R 755 /var/www/bootstrap/cache \
    && chmod +x /var/www/artisan

# Generate application key if .env exists and APP_KEY is not set
RUN if [ -f .env ]; then \
        if ! grep -q "APP_KEY=base64:" .env; then \
            php artisan key:generate --force || echo "Key generation failed, continuing..."; \
        fi; \
    else \
        echo "No .env file found, key generation skipped"; \
    fi

EXPOSE 8000

# Use the correct command for Laravel development server
CMD ["php", "-S", "0.0.0.0:8000", "server.php"]
