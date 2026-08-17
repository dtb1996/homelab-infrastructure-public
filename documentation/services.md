# Services

## Services Summary

| Service                  | Host               | CT ID | Internal Access              | External Access                    | Backup           |
| ------------------------ | ------------------ | :---: | ---------------------------- | ---------------------------------- | ---------------- |
| Proxmox                  | Host               |  N/A  | https://192.0.2.10:8006    | N/A                                | ✅ Configuration |
| Backup Automation        | Host               |  N/A  | Cron                         | N/A                                | N/A              |
| Git Repository           | Host               |  N/A  | `/srv/homelab-git`   | GitHub                             | ✅               |
| Cloudflare               | Cloud              |  N/A  | Dashboard                    | DNS Provider                       | Manual           |
| Homepage                 | Docker LXC         |  100  | http://192.0.2.20:3000    | https://homepage.example.com   | ✅ Docker Config |
| Portainer                | Docker LXC         |  100  | https://192.0.2.20:9443   | https://portainer.example.com  | ✅ Docker Config |
| Samba                    | Docker LXC         |  100  | `\\192.0.2.20`            | N/A                                | ✅ Config        |
| Paperless                | Docker LXC         |  100  | http://192.0.2.20:8010    | https://paperless.example.com  | ✅               |
| Jellyfin                 | Jellyfin LXC       |  101  | http://192.0.2.21:8096      | https://jellyfin.example.com   | ✅ Config        |
| Plex                     | Plex LXC           |  102  | http://192.0.2.22:32400/web | https://plex.example.com       | ✅ Config        |
| Immich                   | Immich LXC         |  TBD  | http://192.0.2.23:2283    | https://photos.example.com     | ✅ Docker Config |
| AdGuard Home (Primary)   | AdGuard LXC        |  110  | http://192.0.2.30:3000      | https://adguard.example.com    | ✅               |
| AdGuard Home (Secondary) | Raspberry Pi       |  N/A  | http://192.0.2.50:3000    | https://adguard-pi.example.com | ✅               |
| Caddy                    | Proxy LXC          |  120  | Reverse Proxy                | Public Entry Point                 | ✅ Config        |
| Syncthing                | Syncthing LXC      |  121  | http://192.0.2.41:8384    | https://sync.example.com       | ✅ LXC Config    |
| Home Assistant           | Home Assistant LXC |  140  | http://192.0.2.42:8123    | https://ha.example.com         | ✅               |
| Uptime Kuma              | Raspberry Pi       |  N/A  | http://192.0.2.50:3001    | https://status.example.com     | ✅               |

## Proxmox

**Location:** Host

**Access**

- Internal: https://192.0.2.10:8006

**Purpose**

Primary hypervisor hosting all virtual machines and Linux containers.

**Dependencies**

- SSD

**Data Location**

`/etc/pve`

**Backup**

Configuration backed up nightly by the Proxmox backup automation.

**Notes**

Hosts all infrastructure services and shared storage.

## Backup Automation

**Location:** Proxmox Host

**Access**

- Internal: Scheduled via cron

**Purpose**

Automates nightly configuration backups and mirrors backups to external storage.

**Dependencies**

- HDD Storage
- USB Storage

**Data Location**

`/srv/backups`

**Backup**

Not applicable (this service performs backups).

**Notes**

Backup scripts are version controlled in the homelab Git repository.

## Git Repository

**Location:** Proxmox Host

**Access**

- Internal: `/srv/homelab-git`
- Remote: GitHub

**Purpose**

Infrastructure as Code repository containing automation scripts, documentation, and configuration files.

**Dependencies**

- GitHub

**Data Location**

`/srv/homelab-git`

**Backup**

Included in nightly Proxmox configuration backups.

**Notes**

Acts as the source of truth for homelab automation and documentation.

## Cloudflare

**Location:** Cloud

**Access**

- Dashboard: https://dash.cloudflare.com

**Purpose**

Provides DNS hosting and ACME DNS validation for TLS certificates.

**Dependencies**

- None

**Data Location**

Cloudflare-managed infrastructure.

**Backup**

Configuration documented manually in this repository.

**Notes**

Used by Caddy for automatic certificate issuance and renewal.

## Homepage

**Location:** Docker LXC (CT100)

**Access**

- Internal: http://192.0.2.20:3000
- External: https://homepage.example.com

**Purpose**

Dashboard for homelab services.

**Dependencies**

- Docker
- Caddy
- AdGuard DNS

**Data Location**

Homepage Docker volume.

**Backup**

Included in Docker configuration backup.

**Notes**

Primary landing page for all homelab services.

## Portainer

**Location:** Docker LXC (CT100)

**Access**

- Internal: https://192.0.2.20:9443
- External: https://portainer.example.com

**Purpose**

Web interface for Docker container management.

**Dependencies**

- Docker
- Caddy
- AdGuard DNS

**Data Location**

Portainer Docker volume.

**Backup**

Included in Docker configuration backup.

**Notes**

Used for day-to-day Docker administration.

## Samba

**Location:** Docker LXC (CT100)

**Access**

- Internal: `\\192.0.2.20`

**Purpose**

Provides cross-platform network file sharing.

**Dependencies**

- Docker
- HDD Storage
- USB Storage

**Data Location**

Shared storage bind mounts.

**Backup**

Configuration included in Docker backup. Shared files are protected separately through storage backups.

**Notes**

Primary file sharing service for the homelab.

## Paperless

**Location:** Docker LXC (CT100)

**Access**

- Internal: http://192.0.2.20:8010
- External: https://paperless.example.com

**Purpose**

Document management system with OCR and search capabilities.

**Dependencies**

- Docker
- HDD Storage
- USB Storage
- Samba (optional import location)

**Data Location**

Paperless data directory and Docker volumes.

**Backup**

Included in Paperless backup automation.

**Notes**

Stores scanned documents and searchable archives.

## Jellyfin

**Location:** Jellyfin LXC (CT101)

**Access**

- Internal: http://192.0.2.21:8096
- External: https://jellyfin.example.com

**Purpose**

Open-source media server.

**Dependencies**

- USB Storage
- Intel iGPU

**Data Location**

Media library and Jellyfin configuration.

**Backup**

Configuration backed up nightly. Media files backed up separately.

**Notes**

Uses Intel Quick Sync for hardware transcoding.

## Plex

**Location:** Plex LXC (CT102)

**Access**

- Internal: http://192.0.2.22:32400/web
- External: https://plex.example.com

**Purpose**

Personal media streaming server.

**Dependencies**

- USB Storage
- Intel iGPU

**Data Location**

Plex metadata and media library.

**Backup**

Configuration backed up nightly. Media files backed up separately.

**Notes**

Configured for Intel Quick Sync hardware transcoding.

## Immich

**Location:** Immich LXC

**Access**

- Internal: http://192.0.2.23:2283
- External: https://photos.example.com

**Purpose**

Self-hosted photo and video management platform.

**Dependencies**

- Docker
- USB Storage

**Data Location**

Immich data directory and Docker volumes.

**Backup**

Included in Docker configuration backup.

**Notes**

Primary replacement for cloud photo storage.

## AdGuard Home (Primary)

**Location:** AdGuard Home LXC (CT110)

**Access**

- Internal: http://192.0.2.30:3000
- External: https://adguard.example.com

**Purpose**

Primary network-wide DNS filtering and ad blocking.

**Dependencies**

- Internet

**Data Location**

AdGuard Home configuration directory.

**Backup**

Included in AdGuard backup automation.

**Notes**

Primary DNS server for the homelab.

## AdGuard Home (Secondary)

**Location:** Raspberry Pi

**Access**

- Internal: http://192.0.2.50:3000
- External: https://adguard-pi.example.com

**Purpose**

Redundant DNS filtering service.

**Dependencies**

- Internet

**Data Location**

Raspberry Pi configuration.

**Backup**

Included in Raspberry Pi backup automation.

**Notes**

Provides DNS redundancy if the Proxmox host is unavailable.

## Caddy

**Location:** Proxy LXC (CT120)

**Access**

- Internal: Reverse proxy
- External: Public entry point for hosted services

**Purpose**

Reverse proxy and automatic TLS certificate management.

**Dependencies**

- Cloudflare DNS
- Internet

**Data Location**

Caddy configuration files.

**Backup**

Included in Docker configuration backup.

**Notes**

Handles HTTPS, reverse proxying, and automatic certificate renewal.

## Syncthing

**Location:** Syncthing LXC (CT121)

**Access**

- Internal: http://192.0.2.41:8384
- External: https://syncthing.example.com

**Purpose**

Provides continuous file synchronization between trusted devices.

Currently used to synchronize Dusklight game save data between the Windows RetroBat system, Android device, and the Syncthing LXC.

**Dependencies**

- Proxmox
- USB Storage
- AdGuard DNS
- Caddy

**Data Location**

Syncthing configuration:

`/var/lib/syncthing/.local/state/syncthing`

Synchronized data:

`/mnt/backup/shared/syncthing`

Mounted into CT121 as:

`/data`

**Backup**

The Syncthing LXC is protected by the standard Proxmox LXC backup and configuration backup processes.

Syncthing configuration, device identities, folder definitions, and service configuration are included with the LXC backup.

Synchronized data is stored on USB storage and is protected separately through the storage backup strategy.

**Notes**

CT121 is an unprivileged LXC running Syncthing under the dedicated syncthing system user.

The container uses a bind mount from `/mnt/backup/shared/syncthing` to `/data`.

The current synchronized folder contains selected Dusklight game data, including `achievements.json` and GameCube memory card save files under the `USA/Card A` directory structure.

Platform-specific files such as configuration files, controller files, `.dat` files, and texture replacement files are excluded using Syncthing ignore patterns.

The Syncthing web interface is accessed through Caddy using `sync.example.com`.

## Home Assistant

**Location:** Home Assistant LXC

**Access**

- Internal: http://192.0.2.42:8123
- External: https://ha.example.com

**Purpose**

Central smart home automation platform.

**Dependencies**

- Caddy
- AdGuard DNS

**Data Location**

`/config`

**Backup**

Included in Home Assistant backup automation.

**Notes**

Monitors and automates homelab backup status and smart home devices.

## Uptime Kuma

**Location:** Raspberry Pi

**Access**

- Internal: http://192.0.2.50:3001
- External: https://status.example.com

**Purpose**

Monitors availability of homelab services and external endpoints.

**Dependencies**

- Internet
- AdGuard DNS

**Data Location**

Uptime Kuma data directory.

**Backup**

Included in Raspberry Pi backup automation.

**Notes**

Provides service status monitoring and outage notifications.
