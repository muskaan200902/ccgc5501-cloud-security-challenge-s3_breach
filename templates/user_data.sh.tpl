#!/bin/bash
# Cloud Breach S3 - Vulnerable Reverse Proxy Setup
# This script configures an intentionally misconfigured nginx reverse proxy

exec > /var/log/user-data.log 2>&1
set -x

# Update system
yum update -y

# Install nginx via amazon-linux-extras (Amazon Linux 2 method)
amazon-linux-extras install nginx1 -y || yum install -y nginx

# Create custom error page
cat > /usr/share/nginx/html/index.html << 'ERRORPAGE'
<!DOCTYPE html>
<html>
<head>
    <title>Proxy Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; background: #1a1a2e; color: #eee; }
        h1 { color: #e94560; }
        .hint { background: #16213e; padding: 20px; border-radius: 5px; margin-top: 20px; }
        code { background: #0f3460; padding: 2px 8px; border-radius: 3px; }
    </style>
</head>
<body>
    <h1>⚠️ Proxy Configuration Error</h1>
    <p>${custom_message}</p>
    <div class="hint">
        <p><strong>Hint:</strong> The metadata service is available at <code>169.254.169.254</code></p>
    </div>
</body>
</html>
ERRORPAGE

# Configure nginx as a vulnerable reverse proxy
cat > /etc/nginx/nginx.conf << 'NGINXCONF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'host="$http_host"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Upstream for metadata service
    upstream metadata {
        server 169.254.169.254:80;
    }

    # Server block that proxies based on Host header
    server {
        listen 80;
        server_name 169.254.169.254;

        # VULNERABILITY: Proxy to metadata service when Host header matches
        location / {
            proxy_pass http://metadata;
            proxy_set_header Host 169.254.169.254;
            proxy_connect_timeout 5s;
            proxy_read_timeout 10s;
        }
    }

    # Default server - shows error page
    server {
        listen 80 default_server;
        server_name _;

        root /usr/share/nginx/html;
        index index.html;

        location / {
            try_files $uri $uri/ /index.html;
        }
    }
}
NGINXCONF

# Test nginx configuration
nginx -t

# Start and enable nginx
systemctl start nginx
systemctl enable nginx

# Verify nginx is running
sleep 2
systemctl status nginx

# Log successful setup
echo "Vulnerable reverse proxy configured successfully" >> /var/log/cloud-breach-setup.log
date >> /var/log/cloud-breach-setup.log
