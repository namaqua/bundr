# Server Setup Guide

## Server Details

- **IP Address:** 85.215.193.34
- **OS:** Ubuntu 24.04.3 LTS (Noble Numbat)
- **CPU:** AMD EPYC-Milan, 8 cores
- **RAM:** 16GB
- **Storage:** 464GB

**Server Users also for collablcoud**
colin │ AggG3MlfR1qk9FiR8ZnMhw== 

robin │ 2nPNPRc3Yvw2k0u7L4s67g== 

## Installed Software

### NGINX (v1.24.0)
- **Installed:** 2026-01-20
- **Config:** /etc/nginx/
- **Web Root:** /var/www/html
- **Service:** `systemctl status nginx`
- **Rate Limiting:** Enabled (10 req/s, burst 20)
- **Security:** Blocks .php, .env, .git, .sql, etc.

### Fail2Ban (v1.0.2)
- **Installed:** 2026-01-20
- **Config:** /etc/fail2ban/jail.local
- **Service:** `systemctl status fail2ban`
- **Active Jails:** 9 jails

| Jail | Protection |
|------|------------|
| sshd | Failed SSH logins (24h ban) |
| nginx-http-auth | Failed HTTP auth |
| nginx-limit-req | Rate limit violations |
| nginx-botsearch | Vulnerability scanners |
| nginx-badbots | Known bad user-agents (24h ban) |
| nginx-bad-request | 400 errors |
| nginx-forbidden | 403 errors |
| nginx-404 | 404 scanners |
| nextcloud | Failed Nextcloud logins |

**Commands:**
```bash
fail2ban-client status          # List all jails
fail2ban-client status sshd     # Check specific jail
fail2ban-client unban <IP>      # Unban an IP
```

### Certbot (v2.9.0)
- **Installed:** 2026-01-20
- **Auto-renewal:** Enabled (systemd timer)
- **Cert location:** /etc/letsencrypt/live/

**Commands:**
```bash
certbot certificates            # List certificates
certbot renew --dry-run         # Test renewal
certbot renew                   # Force renewal
```

## Hosted Sites

### bollmann-roets.de (default)
- **Primary Domain:** bollmann-roets.de, www.bollmann-roets.de
- **Legacy Domain:** bollman-roets.de, www.bollman-roets.de (redirects to primary)
- **Root:** /var/www/bollman-roets.de
- **Config:** /etc/nginx/sites-available/bollman-roets.de
- **URL:** https://bollmann-roets.de
- **SSL:** Let's Encrypt (auto-renews)
- **Cert Path:** /etc/letsencrypt/live/bollmann-roets.de/
- **Current Page:** Holding page ("b & r / Maßgeschneiderte Lösungen / Demnächst")
- **Font:** Outfit (Google Fonts)
- **Deployed:** 2026-01-20

## Directory Structure

```
/var/www/bollman-roets.de  - bollman-roets.de website files
/var/www/html              - Default NGINX placeholder (unused)
/var/docs                  - Documentation (NOT deployed)
/etc/nginx/sites-available - NGINX site configurations
/etc/nginx/sites-enabled   - Active sites (symlinks)
/opt/nextcloud             - Nextcloud installation
/opt/taiga                 - Taiga installation
```

## Access

- **SSH:** `ssh root@85.215.193.34`
- **HTTPS:** https://bollmann-roets.de (HTTP auto-redirects)

## Firewall

UFW is **active** with the following rules:
- OpenSSH (22/tcp) - ALLOW
- Nginx Full (80,443/tcp) - ALLOW
- Default incoming - DENY

```bash
ufw status verbose    # Check firewall status
ufw allow <port>      # Allow a port
ufw deny <port>       # Deny a port
```

### Docker & Docker Compose
- **Installed:** 2026-01-21
- **Service:** `systemctl status docker`

**Commands:**
```bash
docker ps                      # List running containers
docker compose ps              # List containers in current directory
docker compose logs -f         # Follow logs
```

### Nextcloud (collabcloud.bollmann-roets.de)
- **Installed:** 2026-01-21
- **Location:** /opt/nextcloud/
- **Primary URL:** https://collabcloud.bollmann-roets.de
- **Legacy URL:** https://collabcloud.bollman-roets.de (redirects to primary)
- **SSL:** Let's Encrypt (auto-renews)

**Components:**
| Container | Image | Purpose |
|-----------|-------|---------|
| nextcloud-app | nextcloud:29-apache | Main application |
| nextcloud-db | mariadb:10.11 | Database |
| nextcloud-redis | redis:7-alpine | Caching |
| nextcloud-whiteboard | ghcr.io/nextcloud-releases/whiteboard:stable | Real-time whiteboard collaboration |

**Commands:**
```bash
cd /opt/nextcloud
docker compose ps              # Check status
docker compose logs -f app     # Follow Nextcloud logs
docker compose restart         # Restart all containers
./update.sh                    # Update Nextcloud

# Nextcloud CLI (occ)
docker exec -u www-data nextcloud-app php occ status
docker exec -u www-data nextcloud-app php occ app:list
docker exec -u www-data nextcloud-app php occ maintenance:mode --on
docker exec -u www-data nextcloud-app php occ maintenance:mode --off
```

**Installed Apps:**
- Calendar (CalDAV)
- Contacts (CardDAV)
- Talk (Chat/Video)
- Deck (Kanban)
- Tasks
- Whiteboard (Excalidraw-based, real-time collaboration)
- OpenID Connect Provider (OIDC) - identity provider for Taiga SSO

**CalDAV/CardDAV URLs:**
- CalDAV: `https://collabcloud.bollmann-roets.de/remote.php/dav/calendars/<username>/`
- CardDAV: `https://collabcloud.bollmann-roets.de/remote.php/dav/addressbooks/users/<username>/`

**OIDC Clients:**
- Taiga (projects.bollmann-roets.de)

**Whiteboard:**
- Backend URL: `https://collabcloud.bollmann-roets.de/whiteboard`
- Create whiteboards via the "+" menu in Nextcloud Files
- Supports real-time collaboration with multiple users

### Taiga (projects.bollman-roets.de)
- **Installed:** 2026-01-21
- **Location:** /opt/taiga/
- **URL:** https://projects.bollman-roets.de
- **SSL:** Let's Encrypt (auto-renews)
- **Cert Expires:** 2026-04-21
- **SSO:** Enabled via Nextcloud OpenID Connect

**Source:** Custom images based on [kaleidos-ventures/taiga](https://github.com/kaleidos-ventures/taiga) (official) + OpenID plugin

**Components:**
| Container | Image | Purpose |
|-----------|-------|---------|
| taiga-back | taiga-back-openid:local | Backend API + OpenID (custom) |
| taiga-front | taiga-front-openid:local | Frontend + OpenID (custom) |
| taiga-async | taiga-back-openid:local | Async workers (custom) |
| taiga-events | taigaio/taiga-events | WebSocket events |
| taiga-db | postgres:12.3 | PostgreSQL database |
| taiga-gateway | nginx:1.19-alpine | Internal routing |
| taiga-protected | taigaio/taiga-protected | Attachment serving |
| taiga-async-rabbitmq | rabbitmq:3.8 | Async message queue |
| taiga-events-rabbitmq | rabbitmq:3.8 | Events message queue |

**Commands:**
```bash
cd /opt/taiga
docker compose ps              # Check status
docker compose logs -f         # Follow all logs
docker compose logs -f taiga-back  # Follow backend logs
docker compose restart         # Restart all containers
```

**Rebuild Custom Images (to update base images):**
```bash
cd /opt/taiga/custom-images/taiga-back-openid
docker build -t taiga-back-openid:local .

cd /opt/taiga/custom-images/taiga-front-openid
docker build -t taiga-front-openid:local .

cd /opt/taiga
docker compose up -d
```

**Features:**
- Kanban boards
- Scrum with sprint planning
- Backlog management
- Burndown/burnup charts
- Epics and user stories
- Issue tracking
- Wiki documentation
- SSO via CollabCloud (Nextcloud)

**First Login:**
1. Go to https://projects.bollman-roets.de
2. Click "LOGIN WITH COLLABCLOUD"
3. Authenticate with Nextcloud credentials
4. First user to login becomes admin

## System Updates

```bash
apt update && apt upgrade -y
```
