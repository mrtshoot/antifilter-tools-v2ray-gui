#!/bin/bash

# Check if root user is running the script
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# Input parameters
read -p "Please enter your base domain name(example.com): " domain
read -p "Please enter your subdomain name(test): " subdomain
read -p "Please enter your v2ray port: " config_port
read -p "Please enter your email address: " email

# Check if domain is passed as an argument
if [[ -z "$domain" ]]; then
    echo "Please provide a domain name as a parameter"
    exit 1
fi

# Create nginx configuration file
create_nginx_config() {
    echo "Creating Nginx configuration file for '$subdomain.$domain'..."

    # Request Let's Encrypt certificate
    certbot --non-interactive --quiet --agree-tos --email "$email" --redirect --nginx -d "$subdomain.$domain"

    # Create a temporary file for the nginx configuration
    CONF=$(mktemp)

    # Write the configuration to the temporary file
    cat > "$CONF" <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $subdomain.$domain;

    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $subdomain.$domain;
    ssl_certificate /etc/letsencrypt/live/$subdomain.$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$subdomain.$domain/privkey.pem;
    gzip on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types application/javascript application/rss+xml application/vnd.ms-fontobject application/x-font application/x-font-opentype application/x-font-otf application/x-font-truetype application/x-font-ttf application/x-javascript application/xhtml+xml application/xml font/opentype font/otf font/ttf image/svg+xml image/x-icon text/css text/javascript text/plain text/xml;
    
    if (\$host !~ ^($subdomain.$domain)$ ) {
        return 444;
    }

    if (\$request_method !~ ^(GET|HEAD|POST)$ ) {
        return 444;
    }

    access_log /var/log/nginx/$subdomain.$domain.access.log;
    error_log /var/log/nginx/$subdomain.$domain.error.log;

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location / {
        proxy_pass http://localhost:$config_port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
}
EOF

    # Move the temporary file to the Nginx configuration directory
    mv "$CONF" /etc/nginx/sites-available/$subdomain.$domain

    # Enable the site
    ln -s /etc/nginx/sites-available/$subdomain.$domain /etc/nginx/sites-enabled/

    # Remove unnessery files
    rm -f /etc/nginx/sites-available/default
    rm -f /etc/nginx/sites-enabled/default

    # Test nginx configuration
    nginx -t

    # Reload nginx configuration
    systemctl reload nginx

    # Test automatic certificate renewal
    certbot renew --dry-run

    echo "Nginx configuration file for $subdomain.$domain has been created successfully!"

}

# Call the create_nginx_config function
create_nginx_config "$subdomain.$domain $config_port"