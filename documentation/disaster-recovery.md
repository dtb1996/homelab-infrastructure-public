# Disaster Recovery

## Overview

This document outlines the procedures for recovering the homelab after a hardware failure, operating system corruption, or other catastrophic event.

The primary goals are to:

- Restore infrastructure as quickly as possible.
- Minimize data loss.
- Restore core services before application services.
- Rebuild the homelab using Infrastructure as Code whenever possible.

## Recovery Objectives

| Objective                   | Target    |
| --------------------------- | --------- |
| Restore Proxmox Host        | < 1 hour  |
| Restore Core Infrastructure | < 2 hours |
| Restore Primary Services    | < 4 hours |
| Restore Full Homelab        | < 1 day   |

## Recovery Priorities

Infrastructure should always be restored in the following order:

| Priority | Component           |
| -------- | ------------------- |
| 1        | Proxmox Host        |
| 2        | Storage Mounts      |
| 3        | Git Repository      |
| 4        | Backup Repository   |
| 5        | Caddy Reverse Proxy |
| 6        | AdGuard Home        |
| 7        | Docker LXC          |
| 8        | Home Assistant      |
| 9        | Syncthing           |
| 10       | Paperless           |
| 11       | Immich              |
| 12       | Jellyfin            |
| 13       | Plex                |
| 14       | Monitoring Services |

## Recovery Resources

### Local Resources

- Internal HDD (`/srv`)
- Primary USB Backup (`/mnt/backup`)
- Offline USB Backup (2 TB)

### Remote Resources

- GitHub Repository
- Cloudflare DNS

## Disaster Recovery Workflow

1. Hardware Failure
2. Install Proxmox
3. Configure Networking
4. Restore Backup Repository
5. Restore Core Infrastructure
6. Restore Applications
7. Verify Services

## Scenario 1 - Proxmox Reinstallation

### Step 1

Install the latest version of Proxmox VE.

### Step 2

Configure:

- Hostname
- Static IP address
- DNS
- Time zone
- SSH access

### Step 3

Update Proxmox.

```bash
apt update
apt full-upgrade
```

### Step 4

Restore storage configuration.

Verify:

```text
/srv
/mnt/backup
```

are mounted correctly.

### Step 5

Restore any required bind mounts.

### Step 6

Clone the Git repository.

```bash
git clone git@github.com:example/homelab-infrastructure.git
```

### Step 7

Restore Proxmox configuration from backups.

Examples include:

- `/etc/pve`
- Network configuration
- Cron jobs
- Storage configuration

### Step 8

Verify:

```bash
pvesm status
```

## Scenario 2 - Internal HDD Failure

If the internal HDD fails:

1. Replace the drive.
2. Recreate `/srv`.
3. Restore data from `/mnt/backup`.
4. Restore the Git repository.
5. Verify backups.
6. Restore application data as needed.

## Scenario 3 - Primary USB Failure

If the primary USB backup drive fails:

1. Replace the drive.
2. Format and mount the new drive.
3. Restore backup data from the offline USB drive.
4. Resume nightly backup mirroring.

## Scenario 4 - Offline USB Failure

Replace the drive.

Run a manual `rsync` from `/mnt/backup` to the replacement drive.

No additional recovery is required.

## Restoring Individual Services

### Docker

Restore:

- Docker Compose files
- Persistent volumes
- Application data

Redeploy containers.

### Caddy

Restore:

```text
/etc/caddy
```

Validate configuration:

```bash
caddy validate --config /etc/caddy/Caddyfile
```

Reload:

```bash
systemctl reload caddy
```

Verify HTTPS access.

### AdGuard Home

Restore:

- Configuration
- Filters
- DNS settings

Verify clients are resolving DNS correctly.

## Uptime Kuma

Restore:

- Docker Compose configuration
- Uptime Kuma data directory
- Monitoring configuration
- Notification settings

Deploy the Uptime Kuma container.

Verify:

- The web interface is accessible.
- All monitored services are present.
- Notification integrations are functioning.
- Status history and uptime data have been restored (if applicable).

Confirm the service is reachable at:

```text
https://status.example.com
```

### Home Assistant

Restore:

- `/config`
- Automations
- Scripts
- Dashboards

Restart Home Assistant.

### Paperless

Restore:

- Documents
- Metadata
- Docker volumes

Verify OCR and document search.

### Immich

Restore:

- Photo library
- Docker volumes
- Database

Verify photo indexing.

### Jellyfin

Restore:

- Configuration
- Metadata
- Libraries

Verify hardware transcoding.

### Plex

Restore:

- Metadata
- Libraries
- Preferences

Verify hardware transcoding.

## Cloudflare Recovery

If rebuilding the reverse proxy:

Verify:

- DNS records
- Wildcard DNS record
- API token
- DNS Challenge configuration

## Git Recovery

Clone:

```bash
git clone git@github.com:example/homelab-infrastructure.git
```

Restore:

- Documentation
- Backup scripts
- Configuration files
- Docker Compose files

Review recent commits for any configuration changes made after the latest backup.

## Validation Checklist

### Infrastructure

- [ ] Proxmox accessible
- [ ] Storage mounted
- [ ] Git repository restored
- [ ] Backups available

### Network

- [ ] Internet connectivity
- [ ] DNS functioning
- [ ] Cloudflare records verified
- [ ] Reverse proxy reachable

### Services

- [ ] Homepage
- [ ] Portainer
- [ ] Paperless
- [ ] Home Assistant
- [ ] AdGuard Home
- [ ] Jellyfin
- [ ] Plex
- [ ] Immich
- [ ] Uptime Kuma

### Backup

- [ ] Backup scripts operational
- [ ] Nightly cron jobs restored
- [ ] Logs generated
- [ ] Mirroring to `/mnt/backup` functioning

## Lessons Learned

After every recovery or major incident, document:

- Cause of failure
- Recovery duration
- Data loss (if any)
- Improvements to procedures
- Documentation updates
- Infrastructure changes

## Future Improvements

Planned disaster recovery enhancements:

- Automated Proxmox host provisioning
- Automated LXC deployment
- Configuration restoration scripts
- Recovery validation scripts
- Automated backup integrity verification
- Off-site encrypted backup replication
