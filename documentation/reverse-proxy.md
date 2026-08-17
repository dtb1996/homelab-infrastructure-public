# Reverse Proxy

## Overview

The homelab uses **Caddy** as its reverse proxy and **Cloudflare** as the public DNS provider.

External requests are routed through Cloudflare to the Caddy LXC, which terminates HTTPS connections, automatically manages TLS certificates, and forwards requests to the appropriate internal service.

## Architecture

```text
                 Internet
                     |
                     ▼
             Cloudflare DNS
                     |
                     ▼
        Public IP (Home Internet)
                     |
                     ▼
         Router Port Forwarding
               TCP 80 / 443
                     |
                     ▼
            Caddy Reverse Proxy
            Proxy LXC (CT120)
                     │
        ┌────────────┼────────────┐
        |            |            |
        ▼            ▼            ▼
    Homepage    Home Assistant   Paperless
```

## Components

### Cloudflare

#### Responsibilities

- Public DNS hosting
- Wildcard DNS record (`*.example.com`)
- DNS challenge for ACME certificate issuance
- Public hostname management

#### Notes

DNS records are configured as **DNS Only** to allow Caddy to handle TLS termination locally.

A wildcard DNS record allows new subdomains to resolve without requiring additional DNS configuration.

### Router

#### Responsibilities

- Port forwarding
- Internet gateway
- NAT

#### Forwarded Ports

| External Port | Internal Destination |
| ------------: | -------------------- |
|            80 | Caddy LXC            |
|           443 | Caddy LXC            |

### Caddy

**Container:** Proxy LXC (CT120)

#### Responsibilities

- HTTPS termination
- Automatic TLS certificate management
- Reverse proxy
- HTTP → HTTPS redirects
- Request routing

#### Configuration

Caddy uses a modular configuration layout.

```text
/etc/caddy
├── Caddyfile
├── snippets/
└── sites/
```

- `Caddyfile` imports all shared snippets and site definitions.
- `snippets/` contains reusable configuration blocks.
- `sites/` contains one configuration file per proxied service.

Configuration is stored in the Git repository and backed up by the nightly backup process.

## Public Services

| Hostname                   | Internal Destination | Purpose                 |
| -------------------------- | -------------------- | ----------------------- |
| homepage.example.com   | Homepage             | Homelab dashboard       |
| portainer.example.com  | Portainer            | Docker management       |
| paperless.example.com  | Paperless            | Document management     |
| jellyfin.example.com   | Jellyfin             | Media server            |
| plex.example.com       | Plex                 | Media server            |
| photos.example.com     | Immich               | Photo management        |
| ha.example.com         | Home Assistant       | Home automation         |
| adguard.example.com    | AdGuard Home         | Primary DNS dashboard   |
| adguard-pi.example.com | Raspberry Pi AdGuard | Secondary DNS dashboard |
| status.example.com     | Uptime Kuma          | Service monitoring      |

## Request Flow

A typical request follows this path:

1. Browser
2. Cloudflare DNS
3. Home Router
4. Port Forward (80/443)
5. Caddy Reverse Proxy
6. Requested Service

For example:

1. `https://paperless.example.com`
2. Cloudflare DNS
3. Public IP
4. Router (Port 443)
5. Caddy
6. Docker LXC
7. Paperless

## TLS Certificates

TLS certificates are automatically issued and renewed by Caddy using the ACME protocol.

### Certificate Provider

- Let's Encrypt

### Validation Method

- Cloudflare DNS Challenge

## Current Configuration

The homelab uses:

- A wildcard DNS record (`*.example.com`) hosted in Cloudflare.
- Individual TLS certificates automatically issued and renewed by Caddy for each configured hostname.

No wildcard TLS certificate is currently configured.

## Benefits

- Automatic certificate issuance
- Automatic certificate renewal
- No manual certificate management
- HTTPS for every exposed service
- DNS validation works without opening additional ports beyond HTTP/HTTPS

## Configuration Management

The reverse proxy configuration uses a modular layout.

```text
/etc/caddy
├── Caddyfile
├── snippets/
└── sites/
```

- `Caddyfile` imports all shared snippets and site definitions.
- `snippets/` contains reusable configuration blocks.
- `sites/` contains one configuration file per proxied service.

The configuration is version controlled in:

```text
/srv/homelab-git
```

Configuration changes follow this workflow:

1. Modify the appropriate site file or shared snippet.
2. Validate the configuration.
3. Reload the Caddy service.
4. Verify external access.
5. Commit changes to Git.

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
    ├── ...
```

This modular layout keeps each service isolated in its own configuration file while allowing common settings to be shared through reusable snippets.

## Shared Snippets

Reusable configuration is stored in:

```text
/etc/caddy/snippets
```

Current snippets:

| Snippet          | Purpose                       |
| ---------------- | ----------------------------- |
| `security.caddy` | Shared security configuration |

The `security` snippet currently provides:

- Gzip compression
- HTTP Strict Transport Security (HSTS)

Every public service imports this snippet to ensure consistent security settings across the homelab.

## Adding a New Service

The reverse proxy configuration is organized into modular site files.

```text
/etc/caddy
├── Caddyfile
├── snippets/
│   └── security.caddy
└── sites/
    ├── homepage.caddy
    ├── paperless.caddy
    ├── home-assistant.caddy
    ├── immich.caddy
    ├── ...
```

The root `Caddyfile` imports all shared snippets and every site configuration.

Each service is defined in its own `.caddy` file under `sites/`.

Example:

```caddy
homepage.example.com {

    import security

    reverse_proxy 192.0.2.20:3000
}
```

### Deployment Workflow

1. If necessary, create a DNS record in Cloudflare (or rely on the wildcard DNS record).
2. Create a new `.caddy` file in `/etc/caddy/sites/`.
3. Configure the hostname and `reverse_proxy` target.
4. Import the shared `security` snippet.
5. Validate the configuration.

   ```bash
   caddy validate --config /etc/caddy/Caddyfile
   ```

6. Reload Caddy.

   ```bash
   systemctl reload caddy
   ```

7. Verify the TLS certificate is issued successfully.
8. Test both internal and external access.
9. Add the service to Homepage.
10. Update `services.md`.
11. Commit the configuration changes to the Git repository.

## Troubleshooting

### DNS Resolution

Verify the DNS record exists:

```bash
dig <hostname>
```

### Reverse Proxy

Validate the Caddy configuration:

```bash
caddy validate --config /etc/caddy/Caddyfile
```

Reload the configuration:

```bash
systemctl reload caddy
```

Check service status:

```bash
systemctl status caddy
```

View logs:

```bash
journalctl -u caddy -f
```

### TLS Certificates

If certificates fail to issue:

- Verify the Cloudflare API token is valid.
- Confirm the DNS record exists.
- Check that ports 80 and 443 are forwarded correctly.
- Review the Caddy logs for ACME errors.

### Connectivity

From another machine on the network:

```bash
curl -I https://homepage.example.com
```

Verify that:

- DNS resolves correctly.
- HTTPS certificates are valid.
- The request reaches the intended service.

## Security

Current security measures include:

- HTTPS for all externally exposed services.
- Automatic TLS certificate issuance and renewal.
- Cloudflare-managed DNS.
- Wildcard DNS record for `*.example.com`.
- Only ports 80 and 443 exposed to the Internet.
- Shared security configuration applied to every proxied service.
- Reverse proxy isolation from application services.

Future improvements:

- Enable CrowdSec or Fail2Ban.
- Restrict access to administrative services.
- Implement geoblocking where appropriate.
- Add rate limiting for public endpoints.
- Expand the shared security snippet with additional HTTP security headers.

## Related Documentation

- [`services.md`](services.md) - Service inventory and operational details.
- [`network.md`](network.md) - Network topology and DNS architecture.
- [`backup-strategy.md`](backup-strategy.md) - Backup procedures for Caddy and service configurations.
- [`architecture.md`](architecture.md) - Overall homelab architecture.

## Design Principles

The reverse proxy is designed around the following principles:

- One configuration file per service
- Shared reusable configuration snippets
- Automatic HTTPS for every public service
- Infrastructure as Code
- Minimal manual certificate management
- Consistent security headers across all services

## Backup

The following items are backed up nightly:

- `/etc/caddy/Caddyfile`
- `/etc/caddy/sites/`
- `/etc/caddy/snippets/`

Configuration is also version controlled in the Git repository.

## Future Improvements

Planned enhancements include:

- Automatic deployment of Caddy configuration from Git.
- Health checks for proxied services.
- Authentication for administrative dashboards.
- Integration with Home Assistant for reverse proxy monitoring.
- Automated validation of Caddy configuration during Git commits.
