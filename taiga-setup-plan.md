# Taiga Setup Plan

**Goal:** Deploy Taiga with SSO via Nextcloud (CollabCloud)
**Subdomain:** `projects.bollman-roets.de`
**Identity Provider:** `collabcloud.bollman-roets.de` (Nextcloud OIDC)
**Source:** [kaleidos-ventures/taiga](https://github.com/kaleidos-ventures/taiga) (official)

---

## Architecture

```
User Login
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                    Nextcloud (OIDC Provider)                 │
│                  collabcloud.bollman-roets.de                │
│                    Handles authentication                    │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                         Taiga                                │
│                 projects.bollman-roets.de                    │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  Gateway │  │ Frontend │  │ Backend  │  │ Events   │    │
│  │  (nginx) │  │ (Angular)│  │ (Django) │  │ (WS)     │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│                      │              │                        │
│              ┌───────┴──────────────┴───────┐               │
│              │     PostgreSQL + Redis       │               │
│              └──────────────────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

- [x] DNS Record: `projects.bollman-roets.de` → `85.215.193.34` (reuse from OpenProject attempt)
- [x] Nextcloud OIDC Provider app installed
- [x] Create new OIDC client in Nextcloud for Taiga

---

## Implementation Tasks

### Phase 1: Nextcloud OIDC Configuration

- [x] **1.1** Create OIDC client for Taiga in Nextcloud
  ```bash
  docker exec -u www-data nextcloud-app php occ oidc:create \
    'Taiga' \
    'https://projects.bollman-roets.de/api/v1/auth/modules/oidc/callback'
  ```
  - Save Client ID and Client Secret

### Phase 2: Deploy Taiga

- [x] **2.1** Create directory structure
  ```bash
  mkdir -p /opt/taiga
  cd /opt/taiga
  git clone https://github.com/taigaio/taiga-docker.git .
  ```

- [x] **2.2** Configure environment variables
  - Copy `.env.example` to `.env`
  - Set required variables:
    - `TAIGA_DOMAIN=projects.bollman-roets.de`
    - `TAIGA_SCHEME=https`
    - `TAIGA_SECRET_KEY=<generate>`
    - `POSTGRES_PASSWORD=<generate>`
    - `RABBITMQ_PASS=<generate>`

- [x] **2.3** Configure OIDC authentication (using official taigaio images)
  - Edit `docker-compose.yml` or create `docker-compose.override.yml`
  - Add OIDC environment variables to taiga-back and taiga-front:
    ```yaml
    # taiga-back environment
    ENABLE_OPENID: "True"
    OPENID_USER_URL: "https://collabcloud.bollman-roets.de/apps/oidc/userinfo"
    OPENID_TOKEN_URL: "https://collabcloud.bollman-roets.de/apps/oidc/token"
    OPENID_CLIENT_ID: "<from-nextcloud>"
    OPENID_CLIENT_SECRET: "<from-nextcloud>"
    OPENID_SCOPE: "openid email profile"

    # taiga-front environment
    ENABLE_OPENID: "true"
    OPENID_URL: "https://collabcloud.bollman-roets.de/apps/oidc/authorize"
    OPENID_CLIENT_ID: "<from-nextcloud>"
    OPENID_NAME: "CollabCloud"
    OPENID_SCOPE: "openid email profile"
    ```

- [x] **2.4** Pull and start containers

- [x] **2.5** Verify containers are running (9 containers)
  ```bash
  docker compose ps
  ```

### Phase 3: Nginx Reverse Proxy

- [x] **3.1** Create Nginx configuration
  ```bash
  cat > /etc/nginx/sites-available/projects.bollman-roets.de << 'EOF'
  server {
      server_name projects.bollman-roets.de;

      client_max_body_size 100M;

      location / {
          proxy_pass http://127.0.0.1:9000;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;

          # WebSocket support
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
      }

      listen 80;
  }
  EOF
  ```

- [x] **3.2** Enable site and test configuration
  ```bash
  ln -s /etc/nginx/sites-available/projects.bollman-roets.de /etc/nginx/sites-enabled/
  nginx -t
  systemctl reload nginx
  ```

### Phase 4: SSL Certificate

- [x] **4.1** Obtain Let's Encrypt certificate (expires 2026-04-21)
  ```bash
  certbot --nginx -d projects.bollman-roets.de
  ```

### Phase 5: Initial Setup & Verification

- [x] **5.1** Access Taiga at https://projects.bollman-roets.de
- [x] **5.2** Verify "Login with CollabCloud" button appears
- [x] **5.3** Test SSO login flow:
  - Click "Login with CollabCloud"
  - Redirect to Nextcloud login
  - Authenticate with Nextcloud credentials
  - Redirect back to Taiga (logged in)
- [x] **5.4** First user logged in (becomes admin)
- [ ] **5.5** Configure basic settings (project templates, etc.)

### Phase 6: Fail2Ban (Optional)

- [ ] **6.1** Create filter for Taiga failed logins
- [ ] **6.2** Add jail to `/etc/fail2ban/jail.local`

### Phase 7: Documentation

- [x] **7.1** Update `server-setup.md` with Taiga section
- [x] **7.2** Document OIDC client credentials (in docker-compose.override.yml)

---

## Migration: robrotheram → Official taigaio Images

**Goal:** Migrate from `robrotheram/taiga-*-openid` to official `taigaio/taiga-*` images while preserving data and CollabCloud SSO.

### Pre-Migration ✅ COMPLETED

- [x] **M.1** Backup current database
  ```bash
  cd /opt/taiga
  docker compose exec taiga-db pg_dump -U taiga taiga > /opt/taiga/backup-$(date +%Y%m%d).sql
  ```
  - Completed: `/opt/taiga/backup-20260122.sql` (314KB)

- [x] **M.2** Backup current configuration files
  ```bash
  cp /opt/taiga/docker-compose.override.yml /opt/taiga/docker-compose.override.yml.bak
  cp /opt/taiga/.env /opt/taiga/.env.bak
  ```

- [x] **M.3** Document current OIDC credentials (from existing override file)
  - Client ID: `sCxTljoLb5fz2t7Kk6Eyk6HF4wc5Vy7exzvTQ91mr1yW5leEUv2Crzwak4wMcXls`
  - Client Secret: `uNs11iuVwa1fzAdI0faCZNRQ7WxZa6APDqdIQaRqPeQAR2QWu1wAwAKTuvmC9yJq`
  - Note: Already using `OPENID_*` env vars (same as official images)

- [x] **M.4** Backup custom CSS/theme files
  ```bash
  cp /opt/taiga/custom.css /opt/taiga/custom.css.bak
  cp /opt/taiga/theme-taiga-custom.css /opt/taiga/theme-taiga-custom.css.bak
  cp /opt/taiga/taiga-front-nginx.conf /opt/taiga/taiga-front-nginx.conf.bak
  ```
  - Also backed up: conf.json, elements.js

### Migration Steps ✅ COMPLETED

- [x] **M.5** Stop current Taiga containers (keep database running)
  ```bash
  cd /opt/taiga
  docker compose stop taiga-back taiga-front taiga-async taiga-events taiga-gateway taiga-protected
  ```

- [x] **M.6** Update docker-compose.override.yml with new images and env vars
  - Changed `robrotheram/taiga-back-openid` → `taigaio/taiga-back:latest`
  - Changed `robrotheram/taiga-front-openid` → `taigaio/taiga-front:latest`
  - Kept same OPENID_* environment variables (compatible)

- [x] **M.7** Pull new official images
  ```bash
  docker compose pull
  ```

- [x] **M.8** Start containers with new images
  ```bash
  docker compose up -d
  ```
  - All 9 containers running

- [x] **M.9** Run database migrations (if needed)
  ```bash
  docker compose exec taiga-back python manage.py migrate
  ```
  - No migrations needed - schema up to date

### Post-Migration Verification ✅ COMPLETED (Custom Images)

- [x] **M.10** Verify all containers are running - ✅ Passed
- [x] **M.11** Check backend logs for errors - ✅ Passed
- [x] **M.12** Test SSO login flow - ✅ **PASSED** (with custom images)
- [x] **M.13** Verify existing data - ✅ Data intact
- [x] **M.14** Custom CSS - ✅ Applied via conf.json and custom.css

**Solution:** Built custom Docker images extending official taigaio images + OpenID plugin.

### Custom Images (Built 2026-01-22)

**Location:** `/opt/taiga/custom-images/`

**taiga-back-openid:local**
- Base: `taigaio/taiga-back:latest`
- Adds: `taiga-contrib-openid-auth` pip package
- Adds: OpenID configuration to Django settings

**taiga-front-openid:local**
- Base: `taigaio/taiga-front:latest`
- Adds: OpenID plugin files in `/usr/share/nginx/html/plugins/openid-auth/`

**Rebuild Instructions:**
```bash
# Rebuild backend (pulls latest taigaio/taiga-back)
cd /opt/taiga/custom-images/taiga-back-openid
docker build -t taiga-back-openid:local .

# Rebuild frontend (pulls latest taigaio/taiga-front)
cd /opt/taiga/custom-images/taiga-front-openid
docker build -t taiga-front-openid:local .

# Restart with new images
cd /opt/taiga
docker compose up -d
```

### Rollback (if migration fails)

```bash
cd /opt/taiga

# Stop containers
docker compose down

# Restore backup configuration
cp /opt/taiga/docker-compose.override.yml.bak /opt/taiga/docker-compose.override.yml

# Restore database (if corrupted)
docker compose up -d taiga-db
docker compose exec -T taiga-db psql -U taiga taiga < /opt/taiga/backup-YYYYMMDD.sql

# Start with old images
docker compose up -d
```

---

## Resource Requirements

| Service | RAM Usage |
|---------|-----------|
| taiga-gateway | ~50MB |
| taiga-front | ~50MB |
| taiga-back | ~500MB |
| taiga-async | ~200MB |
| taiga-events | ~100MB |
| taiga-db (PostgreSQL) | ~200MB |
| taiga-async-rabbitmq | ~150MB |
| taiga-protected | ~50MB |
| **Total** | **~1.3GB** |

Current server: ~1GB used (Nextcloud)
After Taiga: ~2.5GB
Remaining: ~13GB free

---

## Rollback Plan

```bash
cd /opt/taiga
docker compose down -v
rm -rf /opt/taiga
rm /etc/nginx/sites-enabled/projects.bollman-roets.de
rm /etc/nginx/sites-available/projects.bollman-roets.de
nginx -t && systemctl reload nginx
certbot delete --cert-name projects.bollman-roets.de
docker exec -u www-data nextcloud-app php occ oidc:remove '<client-id>'
```

---

## Verification Checklist

- [x] https://projects.bollman-roets.de loads
- [x] "Login with CollabCloud" button appears
- [x] SSO redirects to Nextcloud
- [x] After Nextcloud login, redirected back to Taiga
- [x] User profile shows correct name/email from Nextcloud
- [ ] Can create a project
- [ ] Kanban board works
- [ ] Sprint planning works

---

## Notes

- Taiga is fully open source (AGPL-3.0)
- All features included: Kanban, Scrum, Epics, Wiki, Issues
- Official images: `taigaio/taiga-back`, `taigaio/taiga-front` (from kaleidos-ventures/taiga)
- OIDC support built into official images via environment variables
- Users from Nextcloud auto-provision on first login
