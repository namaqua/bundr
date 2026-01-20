# Deployment Checklist

## Pre-Deployment

- [ ] Backup current site: `cp -r /var/www/html /var/www/html.bak.$(date +%Y%m%d)`
- [ ] Check disk space: `df -h`
- [ ] Verify NGINX config: `nginx -t`

## Deployment Steps

### 1. Transfer Files
```bash
# From local machine
scp -r ./dist/* root@85.215.193.34:/var/www/html/
```

### 2. Set Permissions
```bash
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
```

### 3. Verify NGINX
```bash
nginx -t
systemctl reload nginx
```

### 4. Test Site
- [ ] Check homepage loads
- [ ] Test all critical pages
- [ ] Verify assets load (CSS, JS, images)

## Post-Deployment

- [ ] Clear any caches if applicable
- [ ] Monitor error logs: `tail -f /var/log/nginx/error.log`
- [ ] Remove old backup after 7 days

## Rollback Procedure

If issues occur:
```bash
# Stop NGINX
systemctl stop nginx

# Restore backup
rm -rf /var/www/html
mv /var/www/html.bak.YYYYMMDD /var/www/html

# Restart NGINX
systemctl start nginx
```

## Emergency Contacts

- Server Admin: [Add contact]
- Hosting Provider: IONOS/1&1
