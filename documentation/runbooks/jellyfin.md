# Jellyfin Runbook

## Overview

This runbook documents the operation, maintenance, backup, and recovery procedures for the Jellyfin media server. Jellyfin runs in its own LXC container and provides media streaming services to devices throughout the home network.

## Container Information

| Property              | Value                 |
| --------------------- | --------------------- |
| Container             | Jellyfin LXC (CT101)  |
| Platform              | Debian LXC            |
| Service               | Jellyfin Media Server |
| Reverse Proxy         | Caddy                 |
| Hardware Acceleration | Intel iGPU            |

## Responsibilities

Jellyfin is responsible for:

- Hosting the personal media library
- Streaming media to client devices
- Managing media metadata
- Providing hardware-accelerated transcoding
- Serving content through the reverse proxy

## Dependencies

Jellyfin depends on:

- Proxmox VE
- Jellyfin LXC container
- Internal network connectivity
- External USB storage (`/mnt/backup`)
- Intel iGPU passthrough
- Caddy reverse proxy
- DNS resolution

## Important Directories

| Path                | Purpose                   |
| --------------------| ------------------------- |
| `/var/lib/jellyfin` | Jellyfin application data |
| `/etc/jellyfin`     | Configuration files       |
| `/media`            | Media storage             |

## Media Storage

Media is stored on the external USB drive: `/mnt/backup/media`

Example layout:

```text
/mnt/backup/media
├── movies/
├── tv/
└── music/
```

The Jellyfin LXC accesses the media storage through a Proxmox mount point.

Verify mounts:

```bash
mount
```

or:

```bash
df -h
```

## Service Management

### Check Status

```bash
systemctl status jellyfin
```

### Restart Jellyfin

```bash
systemctl restart jellyfin
```

### Stop Jellyfin

```bash
systemctl stop jellyfin
```

### Start Jellyfin

```bash
systemctl start jellyfin
```

## Access

Internal:

```text
http://192.0.2.21:8096
```

External:

```text
https://jellyfin.example.com
```

Verify:

- Web interface loads
- Media libraries are available
- Users can authenticate
- Playback works

## Hardware Transcoding

Jellyfin uses the Intel iGPU for hardware acceleration.

Verify GPU availability:

```bash
ls /dev/dri
```

Expected:

```text
card0
renderD128
```

Verify permissions:

```bash
ls -l /dev/dri
```

## Updating Jellyfin

Update package lists:

```bash
apt update
```

Upgrade Jellyfin:

```bash
apt upgrade
```

Restart:

```bash
systemctl restart jellyfin
```

Verify:

```bash
systemctl status jellyfin
```

## Backup

The Jellyfin backup includes:

- Configuration
- Metadata
- Library database
- User settings

Media files are stored separately and are not included in application backups.

Backup location:

```text
/srv/backups
```

Verify backup completion:

```bash
ls /srv/backups
```

Review logs:

```text
/srv/backups/logs
```

## Recovery Procedure

### 1. Restore LXC Container

Restore the Jellyfin LXC from Proxmox backup.

Verify:

```bash
pct list
```

### 2. Restore Configuration

Restore:

```text
/var/lib/jellyfin
/etc/jellyfin
```

### 3. Restore Media Mount

Verify the media mount exists:

```bash
df -h
```

If missing:

- Verify Proxmox mount point configuration.
- Verify `/mnt/backup/media` is mounted.
- Restart the container.

### 4. Verify Hardware Acceleration

Check:

```bash
ls /dev/dri
```

Verify the Jellyfin container can access the GPU device.

### 5. Start Jellyfin

```bash
systemctl start jellyfin
```

### 6. Validate Service

Verify:

- Web interface loads
- Libraries appear
- Media playback works
- Hardware transcoding functions

## Troubleshooting

### Service Won't Start

Check logs:

```bash
journalctl -u jellyfin -f
```

Check configuration:

```bash
systemctl status jellyfin
```

### Media Libraries Missing

Verify:

```bash
ls /media
```

Confirm:

- Storage is mounted.
- Permissions are correct.
- Jellyfin paths are unchanged.

### Playback Issues

Check:

- Client connection quality.
- Media codec compatibility.
- Transcoding status.
- GPU availability.

### Hardware Transcoding Not Working

Verify:

```bash
ls /dev/dri
```

Check Jellyfin playback dashboard: **Dashboard → Active Devices**

Confirm transcoding shows hardware acceleration.

## Maintenance Checklist

### Weekly

- [ ] Verify Jellyfin is running
- [ ] Check storage availability
- [ ] Review logs for errors
- [ ] Verify media libraries scan correctly

### Monthly

- [ ] Update Jellyfin packages
- [ ] Verify hardware acceleration
- [ ] Review metadata storage usage
- [ ] Confirm backups are completing

### Quarterly

- [ ] Test Jellyfin restore procedure
- [ ] Verify media storage health
- [ ] Review library organization
- [ ] Update documentation
