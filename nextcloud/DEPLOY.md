# Nextcloud Deployment Guide

## Prerequisites

1. **DNS Record** - Add A record in IONOS DNS:
   - Host: `collabcloud`
   - Type: `A`
   - Value: `85.215.193.34`
   - TTL: `3600`

2. Wait for DNS propagation (up to 1 hour, usually faster):
   ```bash
   dig collabcloud.bollman-roets.de +short
   # Should return: 85.215.193.34
   ```

---

## Phase 1: Install Docker

SSH into the server:
```bash
ssh root@85.215.193.34
```

Install Docker:
```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh

# Install Docker Compose plugin
apt install docker-compose-plugin -y

# Enable Docker on boot
systemctl enable docker

# Verify installation
docker --version
docker compose version
```

---

## Phase 2: Deploy Nextcloud

Create directory structure:
```bash
mkdir -p /opt/nextcloud/{db,redis,data,config}
cd /opt/nextcloud
```

Copy configuration files from this repo to server:
```bash
# From your local machine:
scp nextcloud/docker-compose.yml root@85.215.193.34:/opt/nextcloud/
scp nextcloud/update.sh root@85.215.193.34:/opt/nextcloud/
```

Create the `.env` file on the server:
```bash
ssh root@85.215.193.34

cd /opt/nextcloud

# Generate passwords
DB_ROOT_PASS=$(openssl rand -base64 32)
DB_PASS=$(openssl rand -base64 32)
ADMIN_PASS=$(openssl rand -base64 32)

# Create .env file
cat > .env << EOF
DB_ROOT_PASSWORD=$DB_ROOT_PASS
DB_PASSWORD=$DB_PASS
ADMIN_USER=admin
ADMIN_PASSWORD=$ADMIN_PASS
EOF

# Save the admin password somewhere secure!
echo "ADMIN PASSWORD: $ADMIN_PASS"

# Secure the .env file
chmod 600 .env
```

Make update script executable:
```bash
chmod +x /opt/nextcloud/update.sh
```

Start Nextcloud:
```bash
docker compose up -d
```

Check logs (wait for initialization):
```bash
docker compose logs -f app
# Wait until you see "apache2 -D FOREGROUND" or similar
# Press Ctrl+C to exit logs
```

---

## Phase 3: Configure Nginx

Copy nginx config to server:
```bash
# From your local machine:
scp collabcloud.bollman-roets.de.conf root@85.215.193.34:/etc/nginx/sites-available/
```

Enable the site and get SSL:
```bash
ssh root@85.215.193.34

# Enable site
ln -s /etc/nginx/sites-available/collabcloud.bollman-roets.de /etc/nginx/sites-enabled/

# Test config
nginx -t

# Reload nginx
systemctl reload nginx

# Get SSL certificate
certbot --nginx -d collabcloud.bollman-roets.de
# Choose: redirect HTTP to HTTPS (option 2)
```

---

## Phase 4: Configure Fail2Ban

Copy fail2ban filter to server:
```bash
# From your local machine:
scp filter.d/nextcloud.conf root@85.215.193.34:/etc/fail2ban/filter.d/
scp jail.local root@85.215.193.34:/etc/fail2ban/
```

Restart Fail2Ban:
```bash
ssh root@85.215.193.34
systemctl restart fail2ban

# Verify Nextcloud jail is active
fail2ban-client status nextcloud
```

---

## Phase 5: Initial Nextcloud Setup

1. Open https://collabcloud.bollman-roets.de in your browser
2. Log in with admin credentials from `.env` file

### Install Required Apps

Go to **Apps** (top-right menu) and install:
- Calendar (may already be installed)
- Contacts (may already be installed)
- Talk
- Deck
- Tasks

### Configure External Storage (Hetzner)

1. Go to **Administration Settings** > **External Storage**
2. Add new external storage:
   - Folder name: `Documents` (or your preference)
   - External storage: `WebDAV`
   - Authentication: `Username and password`
   - URL: Your Hetzner Storage Share WebDAV URL
   - Username: Your Hetzner username
   - Password: Your Hetzner password
   - Available for: All users

### Create User Accounts

1. Go to **Users** in admin menu
2. Create accounts for each family member
3. Set quotas if needed

---

## Verification Checklist

Run these checks after deployment:

```bash
# On server:

# 1. Check containers are running
docker compose ps
# All should show "Up"

# 2. Check Nextcloud status
docker exec -u www-data nextcloud-app php occ status
# Should show: installed: true

# 3. Check Fail2Ban jail
fail2ban-client status nextcloud
# Should show: Currently failed/banned IPs

# 4. Check SSL certificate
certbot certificates
# Should show collabcloud.bollman-roets.de with valid dates
```

From browser:
- [ ] https://collabcloud.bollman-roets.de loads
- [ ] Can log in with admin credentials
- [ ] Calendar app works
- [ ] Contacts app works
- [ ] Talk app works
- [ ] Deck app works
- [ ] https://collabcloud.bollman-roets.de/.well-known/caldav redirects correctly
- [ ] https://collabcloud.bollman-roets.de/.well-known/carddav redirects correctly

---

## Client Setup

### Apple Devices (macOS/iOS)

1. System Settings > Internet Accounts > Add Other Account
2. Choose "CalDAV Account" or "CardDAV Account"
3. Enter:
   - Account Type: Advanced (or Manual)
   - Server: `collabcloud.bollman-roets.de`
   - Username: Your Nextcloud username
   - Password: Your Nextcloud password

For better security, create an App Password in Nextcloud:
1. Settings > Security > Devices & sessions
2. Create new app password
3. Use this password for device connections

### Mobile Apps

Install from app stores:
- **Nextcloud** - File access and sync
- **Nextcloud Talk** - Chat and video calls
- **Nextcloud Deck** - Kanban boards (Android only)

---

## Maintenance

### Updates

Run the update script periodically:
```bash
/opt/nextcloud/update.sh
```

### Backups

Backup these directories:
- `/opt/nextcloud/data` - User files and Nextcloud data
- `/opt/nextcloud/config` - Configuration
- `/opt/nextcloud/db` - Database

Example backup command:
```bash
# Stop containers for consistent backup
cd /opt/nextcloud
docker compose stop

# Backup
tar -czvf /backup/nextcloud-$(date +%Y%m%d).tar.gz /opt/nextcloud

# Start containers
docker compose start
```

### Logs

```bash
# Nextcloud logs
docker compose logs -f app

# Nginx access logs
tail -f /var/log/nginx/collabcloud.bollman-roets.de.access.log

# Fail2Ban logs
tail -f /var/log/fail2ban.log
```

---

## Troubleshooting

### Container won't start
```bash
docker compose logs app
# Check for errors
```

### Database connection error
```bash
docker compose logs db
# Ensure MariaDB is healthy
```

### 502 Bad Gateway
```bash
# Check if Nextcloud container is running
docker ps | grep nextcloud-app

# Check container health
docker compose ps
```

### Permission errors
```bash
# Fix data directory permissions
docker exec nextcloud-app chown -R www-data:www-data /var/www/html
```

### Trusted domain error
```bash
# Add domain to config
docker exec -u www-data nextcloud-app php occ config:system:set trusted_domains 1 --value=collabcloud.bollman-roets.de
```
