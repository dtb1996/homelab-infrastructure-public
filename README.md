# Homelab Infrastructure

This repository serves as the **Infrastructure as Code (IaC)** source for my self-hosted homelab. It contains the automation, configuration exports, and documentation required to deploy, maintain, back up, and recover the environment.

The goal is to treat the homelab like production infrastructure by version controlling configuration, documenting architecture, and automating routine operations wherever possible.

> **Note**
>
> This repository is a sanitized version of my production homelab.
> Sensitive information such as domains, IP addresses, credentials,
> and personal identifiers have been replaced with example values.

## Homelab Overview

### Platform

- **Hypervisor:** Proxmox VE
- **Virtualization:** LXC Containers
- **Container Platform:** Docker
- **Reverse Proxy:** Caddy
- **DNS:** Cloudflare
- **Source Control:** Git
- **File Synchronization:** Syncthing

### Core Services

- Homepage
- Portainer
- Samba
- Paperless-ngx
- Immich
- Home Assistant
- Jellyfin
- Plex
- AdGuard Home (Primary)
- AdGuard Home (Secondary Raspberry Pi)
- Uptime Kuma
- Syncthing

## Repository Structure

```text
homelab-infrastructure/
├── configs/
│   ├── adguard/
│   ├── caddy/
│   ├── docker/
│   ├── homeassistant/
│   ├── homepage/
│   ├── immich/
│   ├── jellyfin/
│   ├── paperless/
│   ├── plex/
│   ├── portainer/
│   ├── proxmox/
│   ├── samba/
│   └── syncthing/
│
├── documentation/
│   ├── architecture.md
│   ├── backup-strategy.md
│   ├── disaster-recovery.md
│   ├── maintenance.md
│   ├── network.md
│   ├── public-repo-sanitization
│   ├── reverse-proxy.md
│   ├── services.md
│   ├── storage.md
│   └── runbooks/
│       ├── adguard.md
│       ├── caddy.md
│       ├── docker.md
│       ├── home-assistant.md
│       ├── immich.md
│       ├── jellyfin.md
│       ├── paperless.md
│       ├── plex.md
│       ├── raspberry-pi.md
│       └── syncthing.md
│
├── scripts/
│   ├── backup/
│   │   ├── backup-all.sh
│   │   ├── backup-docker-config.sh
│   │   ├── backup-homeassistant.sh
│   │   ├── backup-paperless.sh
│   │   ├── backup-pi-config.sh
│   │   ├── backup-proxmox-config.sh
│   │   ├── backup-raspberrypi.sh
│   │   ├── lib/
│   │   └── mirror-backups.sh
│   │
│   ├── deploy/
│   │   └── deploy-pi-backup.sh
│   │
│   ├── export/
│   │   ├── export-configs.sh
│   │   ├── lib/
│   │   └── services/
│   │
│   └── sanitize/
│       ├── sanitize-homeassistant.sh
│       └── sanitize.sh
│
└── README.md
```

## Repository Layout

### configs/

Contains exported infrastructure configuration that is safe to version control.

Examples include:

- Proxmox configuration
- Docker Compose stacks
- Home Assistant configuration
- Caddy configuration
- Jellyfin configuration
- AdGuard configuration
- Syncthing configuration
- Service configuration documentation

Sensitive files are sanitized before export.

### documentation/

Operational documentation for the homelab.

Includes:

- Architecture
- Networking
- Storage
- Backup strategy
- Disaster recovery
- Maintenance procedures
- Service inventory

### Runbooks

The `documentation/runbooks` directory contains operational procedures for each major service.

Each runbook documents:

- Installation
- Configuration
- Backup strategy
- Restore procedures
- Maintenance tasks
- Upgrade procedures
- Troubleshooting

These documents are intended to allow rebuilding any service from scratch.

### scripts/

Automation used to operate the homelab.

#### backup/

Nightly backup automation including:

- Proxmox configuration
- Docker configuration
- Paperless
- Home Assistant
- Raspberry Pi
- Backup mirroring
- Logging
- Inventory generation

#### deploy/

Deployment utilities for infrastructure.

#### export/

Exports the current configuration of the homelab into the `configs/` directory.

The export process:

- Copies configuration files
- Removes secrets
- Generates documentation
- Produces deployment templates
- Can optionally create an automatic Git commit

This script is executed nightly after backups complete so Git always reflects the latest infrastructure state.

#### sanitize/

Utilities for preparing the repository for public distribution.

The sanitization process:

Removes personal information
Replaces private infrastructure details with example values
Removes sensitive configuration
Sanitizes service-specific paths and identifiers
Provides safe replacements for files that cannot be published as-is

Sanitization is performed separately from the normal configuration export so the private infrastructure repository can retain its complete configuration while a sanitized copy can be published publicly.

## Documentation

The `documentation/` directory serves as the operational documentation for the homelab.

| Document                                                     | Description                                  |
| ------------------------------------------------------------ | -------------------------------------------- |
| [`architecture.md`](documentation/architecture.md)           | High-level architecture and design           |
| [`services.md`](documentation/services.md)                   | Service inventory and operational details    |
| [`network.md`](documentation/network.md)                     | Network layout                               |
| [`storage.md`](documentation/storage.md)                     | Storage layout and backup destinations       |
| [`reverse-proxy.md`](documentation/reverse-proxy.md)         | Caddy and Cloudflare configuration           |
| [`backup-strategy.md`](documentation/backup-strategy.md)     | Backup architecture and retention            |
| [`maintenance.md`](documentation/maintenance.md)             | Routine maintenance procedures               |
| [`disaster-recovery.md`](documentation/disaster-recovery.md) | Disaster recovery and restoration procedures |
| [`runbooks/`](documentation/runbooks/)                       | Service-specific operational guides          |

## Automation

The repository contains scripts used to automate infrastructure management, including:

- Nightly backup orchestration
- Proxmox configuration backups
- Docker backups
- Home Assistant backups
- Paperless backups
- Raspberry Pi backups
- Backup mirroring
- Inventory generation
- Configuration exports
- Automatic Git commits

Backup scripts are version controlled here, while backup archives are stored separately on dedicated storage devices.

## Why Export Configurations to Git?

Proxmox's built-in backup system creates complete snapshots of containers and virtual machines, making it ideal for disaster recovery. However, VM/LXC backups are binary archives and are not well suited for:

- Reviewing configuration changes
- Tracking infrastructure history
- Code reviews
- Documentation
- Restoring individual configuration files
- Rebuilding services from scratch

This repository complements Proxmox backups by exporting configuration into a human-readable, version-controlled format.

Benefits include:

- Full Git history of infrastructure changes
- Easy comparison between revisions
- Recover individual configuration files
- Infrastructure documentation alongside configuration
- Simplified migration to new hardware
- Reproducible deployments
- Infrastructure as Code workflow

Together they provide two complementary layers:

| Proxmox Backups           | Git Configuration Exports  |
| ------------------------- | -------------------------- |
| Disaster recovery         | Version history            |
| Full VM/LXC restore       | Individual file restore    |
| Binary archives           | Human-readable text        |
| Point-in-time snapshots   | Continuous change tracking |
| Operating system included | Configuration only         |

Using both provides significantly more flexibility than relying on either approach alone.

## Infrastructure Principles

This homelab is built around the following principles:

- Infrastructure as Code
- Automation first
- Version-controlled configuration
- Comprehensive documentation
- Layered backup strategy
- Disaster recovery planning
- Reproducible deployments
- Minimal manual intervention

## Backup Strategy

The homelab uses multiple independent backup layers.

1. **Proxmox Backups**

   Nightly LXC backups stored on dedicated HDD storage.

2. **Configuration Exports**

   Nightly export of service configuration into Git.

3. **Git Version History**

   Infrastructure changes tracked through commits.

4. **External Backup**

   Backup mirror synchronized to external USB storage.

5. **Offline Backup**

   Periodic manual synchronization to an offline USB drive.

This layered approach protects against accidental deletion, configuration mistakes, storage failure, and complete host loss.

## Roadmap

Planned improvements include:

- Automated infrastructure deployment
- Docker Compose templating
- Proxmox provisioning automation
- Configuration validation
- CI/CD for infrastructure changes
- Health checks
- Backup verification
- Secret management improvements
- Automated restore testing
