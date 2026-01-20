# NGINX Configuration Reference

## Common Commands

```bash
# Test configuration syntax
nginx -t

# Reload configuration (graceful)
systemctl reload nginx

# Restart NGINX
systemctl restart nginx

# Stop NGINX
systemctl stop nginx

# Start NGINX
systemctl start nginx

# Check status
systemctl status nginx
```

## Configuration Files

| Path | Purpose |
|------|---------|
| `/etc/nginx/nginx.conf` | Main config file |
| `/etc/nginx/sites-available/` | Site configurations |
| `/etc/nginx/sites-enabled/` | Active sites (symlinks) |
| `/etc/nginx/conf.d/` | Additional config snippets |

## Log Files

```bash
# Access log
tail -f /var/log/nginx/access.log

# Error log
tail -f /var/log/nginx/error.log
```

## Enable/Disable Sites

```bash
# Enable a site
ln -s /etc/nginx/sites-available/mysite /etc/nginx/sites-enabled/

# Disable a site
rm /etc/nginx/sites-enabled/mysite

# Always test and reload after changes
nginx -t && systemctl reload nginx
```

## Basic Server Block Template

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    root /var/www/html;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    # Logs
    access_log /var/log/nginx/example.access.log;
    error_log /var/log/nginx/example.error.log;
}
```

## SSL/HTTPS Setup (Certbot)

```bash
# Install Certbot
apt install certbot python3-certbot-nginx

# Obtain certificate
certbot --nginx -d example.com -d www.example.com

# Auto-renewal test
certbot renew --dry-run
```

## Performance Tips

```nginx
# Enable gzip compression
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml;

# Browser caching for static files
location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```
