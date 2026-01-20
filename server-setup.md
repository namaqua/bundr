# Server Setup Guide

## Server Details

- **IP Address:** 85.215.193.34
- **OS:** Ubuntu 24.04.3 LTS (Noble Numbat)
- **CPU:** AMD EPYC-Milan, 8 cores
- **RAM:** 16GB
- **Storage:** 464GB

## Installed Software

### NGINX (v1.24.0)
- **Installed:** 2026-01-20
- **Config:** /etc/nginx/
- **Web Root:** /var/www/html
- **Service:** `systemctl status nginx`

### Fail2Ban (v1.0.2)
- **Installed:** 2026-01-20
- **Config:** /etc/fail2ban/jail.local
- **Service:** `systemctl status fail2ban`
- **Active Jails:** sshd, nginx-http-auth, nginx-limit-req, nginx-botsearch

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

### bollman-roets.de (default)
- **Root:** /var/www/bollman-roets.de
- **Config:** /etc/nginx/sites-available/bollman-roets.de
- **URL:** https://bollman-roets.de
- **SSL:** Let's Encrypt (auto-renews)
- **Cert Expires:** 2026-04-20
- **Cert Path:** /etc/letsencrypt/live/bollman-roets.de/
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
```

## Access

- **SSH:** `ssh root@85.215.193.34`
- **HTTPS:** https://bollman-roets.de (HTTP auto-redirects)

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

## System Updates

```bash
apt update && apt upgrade -y
```
