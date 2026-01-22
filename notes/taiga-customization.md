# Taiga Customization Reference

## Project Overview
Customizing Taiga at **projects.bollman-roets.de** with B&R branding.
**Source:** Custom images based on [kaleidos-ventures/taiga](https://github.com/kaleidos-ventures/taiga) + OpenID plugin

## Current Status

### Completed
- SSO via Nextcloud working
- Theme CSS modified: replaced `#008aa8` → `#58cf39` (green), grey colors → white
- Custom CSS at `/opt/taiga/custom.css` with B&R logo, Outfit font, dark grey buttons
- Nginx config at `/opt/taiga/taiga-front-nginx.conf` with redirects and CSS injection

### Outstanding Issue
Color `#83eede` still appears on Kanban page. It's **hardcoded in JavaScript**, not just CSS.

**Note (2026-01-22):** Migrated to custom images based on official taigaio. Frontend version is now `v-1760376509003` (was `v-1631701833072`). Old elements.js and theme-taiga-custom.css are not compatible with new version. Custom branding applied via custom.css only.

## Server Files

| File | Purpose |
|------|---------|
| `/opt/taiga/docker-compose.override.yml` | Docker compose overrides |
| `/opt/taiga/custom.css` | Custom CSS with B&R logo, Outfit font, dark grey buttons |
| `/opt/taiga/theme-taiga-custom.css` | Modified theme CSS |
| `/opt/taiga/taiga-front-nginx.conf` | Nginx config with redirects and CSS injection |
| `/opt/taiga/conf.json` | Taiga frontend configuration |

## Color Scheme

| Original | Replacement | Usage |
|----------|-------------|-------|
| `#008aa8` | `#58cf39` | Primary green |
| Grey colors | White | Background/UI elements |
| `#83eede` | TBD | Kanban page (hardcoded in JS) |

## Server Access
```bash
ssh root@85.215.193.34
```

## Commands

### Find all JS files containing #83eede
```bash
ssh root@85.215.193.34 'docker exec taiga-taiga-front-1 grep -l "83eede" /usr/share/nginx/html/v-1631701833072/js/*.js'
```

## Fix Strategy for #83eede

Need to modify the JS file `elements.js` in the container or mount a modified version, similar to how `theme-taiga-custom.css` is handled.

Options:
1. Extract `elements.js` from container, modify it, mount the modified version via docker-compose override
2. Use sed/awk replacement in container entrypoint
3. Create a JavaScript override that runs after page load to replace colors dynamically
