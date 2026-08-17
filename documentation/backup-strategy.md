# Backup Strategy

## Overview

The homelab follows a **3-tier backup strategy** designed to protect against hardware failure, configuration loss, and accidental deletion, while providing a clear disaster recovery path.

### Backup Tiers

| Tier   | Storage                | Purpose                      |
| ------ | ---------------------- | ---------------------------- |
| Tier 1 | `/srv/backups` | Local backup repository      |
| Tier 2 | `/mnt/backup`         | External backup copy         |
| Tier 3 | Offline 2 TB USB Drive | Manual offline backup mirror |

This strategy ensures that backups exist on multiple storage devices, including one copy that remains offline and isolated from the running system.

## Backup Schedule

### Nightly Backup

Runs automatically via cron on the Proxmox host and performs the following tasks:

1. Backup Proxmox configuration
2. Backup Docker configurations
3. Backup Paperless data
4. Backup Home Assistant configuration
5. Backup Raspberry Pi configuration
6. Generate inventories
7. Generate backup logs
8. Update latest backup references
9. Mirror backups to the primary external USB drive

## Backup Targets

### Proxmox

#### Includes

- `/etc/pve`
- Storage configuration
- Network configuration
- System configuration
- Cron jobs
- Installed package list

#### Destination

```text
/srv/backups/proxmox
```

### Docker

#### Includes

- Docker Compose files
- Container configuration
- Named volumes
- Persistent application data

#### Destination

```text
/srv/backups/docker
```

### Paperless

#### Includes

- Configuration
- Docker volumes
- Metadata
- Documents

#### Destination

```text
/srv/backups/paperless
```

### Home Assistant

#### Includes

- Configuration
- Automations
- Scripts
- Scenes
- Dashboards
- Custom integrations

#### Destination

```text
/srv/backups/homeassistant
```

### Raspberry Pi

#### Includes

- AdGuard Home configuration
- Uptime Kuma configuration
- System configuration

#### Destination

```text
/srv/backups/raspberrypi
```

### Git Repository

The Git repository is version controlled separately through GitHub.

#### Includes

- Documentation
- Backup scripts
- Configuration files
- Docker Compose files

#### Location

```text
/srv/homelab-git
```

## Backup Repository Structure

```text
/srv/backups
├── docker/
├── homeassistant/
├── paperless/
├── proxmox/
├── raspberrypi/
├── latest/
├── logs/
└── status/
```

## Backup Workflow

1. Nightly Cron
2. Run Backup Scripts
3. Generate Archives
4. Generate Inventories
5. Generate Logs
6. Update Latest Copies
7. Mirror to /mnt/backup

## External Backup

After nightly backups complete, the backup repository is mirrored to:

```text
/mnt/backup
```

This provides a second copy on physically separate storage.

## Offline Backup

An additional 2 TB USB drive is maintained as an offline backup. Unlike the primary USB drive, this drive:

- Is not permanently connected
- Is mounted manually
- Receives periodic manual synchronization using `rsync`
- Is disconnected after synchronization

This protects against:

- Hardware failure
- Accidental deletion
- Filesystem corruption

## Backup Retention

Current retention policies are defined within the backup scripts and is managed independently for each backup type.

Examples include:

- Daily backups
- Rotating archives
- Inventory snapshots
- Backup logs

## Monitoring

Each backup run generates:

- Backup logs
- Inventory reports
- Status files
- Success/failure summaries

Home Assistant monitors backup status and displays the current health of the backup system. A push notification is triggered if any of the jobs fail.

Future improvements may include:

- Email notifications
- Automatic restore verification

## Disaster Recovery

In the event of a failure:

1. Install Proxmox VE.
2. Restore networking.
3. Restore storage configuration.
4. Clone the Git repository.
5. Restore Proxmox configuration.
6. Restore Docker services.
7. Restore Home Assistant.
8. Restore Paperless.
9. Restore Raspberry Pi configurations.
10. Verify reverse proxy and DNS.
11. Validate all services.

## Recovery Priority

| Priority | Service               |
| -------- | --------------------- |
| 1        | Proxmox Host          |
| 2        | Storage Configuration |
| 3        | Caddy Reverse Proxy   |
| 4        | AdGuard Home          |
| 5        | Docker LXC            |
| 6        | Home Assistant        |
| 7        | Syncthing             |
| 8        | Paperless             |
| 9        | Immich                |
| 10       | Jellyfin              |
| 11       | Plex                  |

Infrastructure services are restored before application services to minimize downtime.

## Design Goals

The backup strategy is designed to:

- Maintain multiple copies of critical data.
- Keep one backup copy offline.
- Separate backups from the operating system.
- Automate routine backup tasks.
- Preserve infrastructure as code using Git.
- Support rapid disaster recovery.
- Minimize manual intervention.

## Future Improvements

Planned enhancements include:

- Automated restore testing
- Backup integrity verification
- SMART health monitoring
- Off-site cloud replication for critical configuration data
- Automated backup reporting dashboards in Home Assistant
