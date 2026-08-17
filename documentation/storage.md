# Storage

## Overview

The homelab uses a tiered storage strategy that separates the operating system, persistent data, and backups across dedicated storage devices.

| Storage            | Size   | Mount Point    | Purpose                                               |
| ------------------ | ------ | -------------- | ----------------------------------------------------- |
| SSD                | 223 GB | `/`            | Proxmox OS, LXC/VM disks, local-lvm storage           |
| Internal HDD       | 465 GB | `/srv` | Persistent data, Git repository, backups, Docker data |
| External USB Drive | 4 TB   | `/mnt/backup` | Primary backup destination and media storage          |
| External USB Drive | 2 TB   | `/mnt/import/` | Offline backup mirror                                 |

## Storage Devices

### SSD (`/dev/sdb`)

**Size:** 223 GB

**Mount Point:** `/`

#### Purpose

- Proxmox VE operating system
- LXC root disks
- VM disks
- Local-LVM storage
- Swap

#### Layout

| Partition / Volume | Purpose                  |
| ------------------ | ------------------------ |
| `/dev/sdb1`        | BIOS Boot                |
| `/dev/sdb2`        | EFI System Partition     |
| `/dev/sdb3`        | Proxmox LVM              |
| `pve-root`         | Proxmox operating system |
| `pve-swap`         | Swap                     |
| `pve-data`         | VM/LXC virtual disks     |

#### Current LXC Virtual Disks

| Volume          | Service             |
| --------------- | ------------------- |
| `vm-100-disk-0` | Docker              |
| `vm-110-disk-0` | AdGuard Home        |
| `vm-131-disk-0` | Home Assistant      |
| `vm-140-disk-0` | Caddy Reverse Proxy |

#### Notes

The SSD is reserved for the operating system and virtual machine storage to maximize performance.

### Internal HDD (`/dev/sda`)

**Size:** 465 GB

**Mount Point:** `/srv`

#### Purpose

- Persistent application data
- Configuration backups
- Git repository
- Docker volumes
- Shared storage
- ISO images
- Scripts

#### Directory Layout

```text
/srv
├── backups/
├── docker/
├── homelab-git/
├── iso/
├── media/
└── shares/
```

#### Backups

```text
/srv/backups
```

Contains:

- Proxmox configuration backups
- LXC configuration backups
- Home Assistant backups
- Docker backups
- Paperless backups
- Raspberry Pi backups
- Backup logs
- Inventory reports

#### Git Repository

```text
/srv/homelab-git
```

Stores:

- Infrastructure documentation
- Backup automation scripts
- Configuration files
- Docker Compose files
- Homelab documentation

#### Notes

This drive contains all persistent data that should survive a Proxmox reinstall.

### External USB Drive (`/dev/sdd`)

**Size:** 4 TB

**Mount Point:** `/mnt/backup`

#### Purpose

Primary external storage for:

- Backup archives
- Media library
- Long-term storage
- Backup mirror destination

This drive is mounted automatically during normal operation.

#### Notes

Acts as the primary external storage device for both media and backups.

### External USB Drive (`/dev/sde`)

**Size:** 2 TB

**Mount Point:** Manual (not permanently mounted)

#### Purpose

Offline backup mirror.

This drive is intentionally **not mounted automatically**. It is only mounted when manually syncing the contents of the primary USB drive using `rsync`.

Typical workflow:

1. Connect drive
2. Mount drive
3. Run manual `rsync`
4. Verify synchronization
5. Unmount drive
6. Disconnect drive

#### Notes

Keeping this drive offline protects it from:

- Accidental deletion
- Filesystem corruption
- Malware or ransomware
- User error

## Storage Architecture

```text
               Proxmox Host
                     │
       ┌─────────────┴────────────────┐
       │                              │
      SSD                       Internal HDD
  Local-LVM                     /srv
(VM/LXC Disks)                        |
                                      │
        ┌─────────────────┬───────────┴─────┐
        │                 │                 │
   Docker Data      Git Repository       Backups
                                            │
                                            │
                                            ▼
                                   External USB (4 TB)
                                      /mnt/backup
                                            │
                                      Manual rsync
                                            │
                                            ▼
                                   External USB (2 TB)
                                      Offline Copy
```

## Storage Usage

| Storage             | Contents                                                     |
| ------------------- | ------------------------------------------------------------ |
| SSD                 | Proxmox OS, VM/LXC disks, Local-LVM                          |
| Internal HDD        | Persistent data, Git repository, backups, Docker data, media |
| External USB (4 TB) | Backup archives, media storage, long-term storage            |
| External USB (2 TB) | Offline backup mirror                                        |

## Backup Storage Strategy

| Source                 | Destination                             |
| ---------------------- | --------------------------------------- |
| Proxmox Configuration  | `/srv/backups`                  |
| LXC Configurations     | `/srv/backups`                  |
| Docker Configurations  | `/srv/backups`                  |
| Home Assistant         | `/srv/backups`                  |
| Raspberry Pi           | `/srv/backups`                  |
| `/srv/backups` | `/mnt/backup`                          |
| `/mnt/backup`         | Offline 2 TB USB drive (manual `rsync`) |

## Design Goals

The storage layout is designed around the following principles:

- Separate the operating system from persistent application data.
- Keep VM and LXC disks on fast SSD storage.
- Store persistent data on a dedicated internal HDD.
- Maintain local backups before copying them to external storage.
- Maintain an offline backup copy that is isolated from the running system.
- Version control infrastructure and automation using Git.

## Future Improvements

Planned storage enhancements include:

- Dedicated NAS
- RAID or ZFS storage
- Additional SSD capacity for virtual machines
- SMART monitoring and alerting
- Automated backup verification
- Expansion to 10 Gb networking
