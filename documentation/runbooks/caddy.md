# Caddy Runbook

## Overview

This runbook documents the operation, maintenance, backup, and recovery procedures for the Caddy reverse proxy. Caddy runs in its own dedicated LXC container and serves as the single ingress point for all externally accessible homelab services.

## Container Information

| Property          | Value                    |
| ----------------- | ------------------------ |
| Container         | Proxy LXC (CT120)        |
| Service           | Caddy                    |
| Purpose           | Reverse Proxy            |
| DNS Provider      | Cloudflare               |
| TLS Provider      | Let's Encrypt            |
| Validation Method | Cloudflare DNS Challenge |

## Responsibilities

Caddy is responsible for:

- HTTPS termination
- Automatic TLS certificate issuance
- Automatic certificate renewal
- Reverse proxying
- HTTP to HTTPS redirects
- Request routing
- Shared security configuration

## Dependencies

Caddy depends on:

- Proxmox VE
- Cloudflare DNS
- Internet connectivity
- Router port forwarding (80/443)
- Hosted backend services

## Configuration Layout

```text
/etc/caddy
├── Caddyfile
├── snippets/
│   └── security.caddy
└── sites/
    ├── homepage.caddy
    ├── paperless.caddy
    ├── home-assistant.caddy
    ├── plex.caddy
    ├── jellyfin.caddy
    ├── immich.caddy
    ├── adguard-primary.caddy
    ├── adguard-pi.caddy
    ├── uptime-kuma.caddy
    └── ...
```

## Important Files

| Path                   | Purpose                       |
| ---------------------- | ----------------------------- |
| `/etc/caddy/Caddyfile` | Root configuration            |
| `/etc/caddy/sites/`    | Individual site definitions   |
| `/etc/caddy/snippets/` | Shared configuration snippets |
| `/var/lib/caddy`       | Runtime data                  |
| `/var/log`             | System logs (via journald)    |

## Current Public Services

| Hostname                   | Backend              |
| -------------------------- | -------------------- |
| homepage.example.com   | Homepage             |
| portainer.example.com  | Portainer            |
| paperless.example.com  | Paperless            |
| jellyfin.example.com   | Jellyfin             |
| plex.example.com       | Plex                 |
| photos.example.com     | Immich               |
| ha.example.com         | Home Assistant       |
| adguard.example.com    | Primary AdGuard      |
| adguard-pi.example.com | Raspberry Pi AdGuard |
| status.example.com     | Uptime Kuma          |

## Service Management

Check status:

```bash
systemctl status caddy
```

Start:

```bash
systemctl start caddy
```

Stop:

```bash
systemctl stop caddy
```

Restart:

```bash
systemctl restart caddy
```

Reload configuration:

```bash
systemctl reload caddy
```

Enable at boot:

```bash
systemctl enable caddy
```

## Health Checks

Verify service status:

```bash
systemctl status caddy
```

Validate configuration:

```bash
caddy validate --config /etc/caddy/Caddyfile
```

Verify HTTPS:

```bash
curl -I https://homepage.example.com
```

Confirm:

- HTTPS works
- Correct certificate is presented
- Requests reach backend services

## Configuration Management

The root configuration imports all site definitions and shared snippets.

```caddy
{
    email user@example.com
}

import snippets/*
import sites/*
```

Every public service is configured in its own `.caddy` file.

Example:

```caddy
homepage.example.com {
    import security

    reverse_proxy 192.0.2.20:3000
}
```

## Shared Snippets

Reusable configuration lives in:

```text
/etc/caddy/snippets
```

Current snippets:

| Snippet          | Purpose                       |
| ---------------- | ----------------------------- |
| `security.caddy` | Shared security configuration |

Current shared configuration includes:

- Gzip compression
- HTTP Strict Transport Security (HSTS)

All public services import this snippet.

## Adding a New Service

### 1. Verify Backend

Confirm the application is running internally.

### 2. Create a Site Configuration

Create:

```text
/etc/caddy/sites/<service>.caddy
```

Example:

```caddy
example.example.com {
    import security

    reverse_proxy 192.0.2.92:8080
}
```

### 3. Validate Configuration

```bash
caddy validate --config /etc/caddy/Caddyfile
```

### 4. Reload Caddy

```bash
systemctl reload caddy
```

### 5. Verify

Confirm:

- HTTPS works
- Certificate is issued
- Backend is reachable

### 6. Update Documentation

Update:

- `services.md`
- Homepage dashboard (if applicable)

Commit the new configuration to Git.

## Backup

Nightly backups include:

- `/etc/caddy`
- Site configurations
- Shared snippets

The configuration is also version controlled in:

```text
/srv/homelab-git
```

## Recovery Procedure

### 1. Restore the LXC

Restore the Proxy LXC from the latest Proxmox backup.

Verify:

```bash
pct list
```

### 2. Restore Configuration

Restore:

```text
/etc/caddy
```

Verify:

```bash
ls /etc/caddy
```

### 3. Validate Configuration

```bash
caddy validate --config /etc/caddy/Caddyfile
```

Resolve any configuration errors before proceeding.

### 4. Start Caddy

```bash
systemctl start caddy
```

### 5. Verify Public Services

Confirm:

- DNS resolves correctly.
- HTTPS certificates are issued.
- All configured services are reachable.

## Troubleshooting

### Configuration Errors

Validate:

```bash
caddy validate --config /etc/caddy/Caddyfile
```

### Service Won't Start

```bash
systemctl status caddy
```

View logs:

```bash
journalctl -u caddy -f
```

### HTTPS Issues

Verify:

- Cloudflare DNS records
- Internet connectivity
- Ports 80 and 443 are forwarded
- ACME challenge succeeds

### Backend Unreachable

Verify:

```bash
curl http://<backend-ip>:<port>
```

Confirm:

- Backend service is running.
- IP address is correct.
- Port is correct.

### DNS Problems

Verify:

```bash
dig homepage.example.com
```

Confirm the hostname resolves to the public IP address.

## Maintenance Checklist

### Weekly

- [ ] Review Caddy logs
- [ ] Verify public services
- [ ] Validate configuration after changes

### Monthly

- [ ] Review site configurations
- [ ] Remove unused routes
- [ ] Review shared snippets
- [ ] Verify automatic certificate renewal

### Quarterly

- [ ] Audit all public services
- [ ] Review security configuration
- [ ] Test reverse proxy recovery
- [ ] Update documentation

## Verification Checklist

After maintenance or recovery, verify:

- [ ] Caddy is running.
- [ ] Configuration validates successfully.
- [ ] All hostnames resolve.
- [ ] HTTPS works for every service.
- [ ] Certificates are valid.
- [ ] Reverse proxy routes correctly.
- [ ] Homepage links function.
- [ ] External access is operational.
