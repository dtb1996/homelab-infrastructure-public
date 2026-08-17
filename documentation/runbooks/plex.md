# Plex Runbook

## Overview

This runbook documents the operation, maintenance, backup, and recovery procedures for the Plex media server. Plex runs in its own LXC container and provides media streaming services to devices throughout the home network.

## Container Information

| Property              | Value             |
| --------------------- | ----------------- |
| Container             | Plex LXC (CT102)  |
| Platform              | Debian LXC        |
| Service               | Plex Media Server |
| Reverse Proxy         | Caddy             |
| Hardware Acceleration | Intel iGPU        |

## Responsibilities

Plex is responsible for:

- Hosting the personal media library
- Streaming media to client devices
- Managing media metadata
- Providing hardware-accelerated transcoding
- Serving content through the reverse proxy

## Dependencies

Plex depends on:

- Proxmox VE
- Plex LXC container
- Internal network connectivity
- External USB storage (`/mnt/backup`)
- Intel iGPU passthrough
- Caddy reverse proxy
- DNS resolution

## Important Directories

| Path                       | Purpose               |
| -------------------------- | --------------------- |
| `/var/lib/plexmediaserver` | Plex application data |
| `/media`                   | Media storage         |

## Media Storage

Media is stored on the external USB drive:

```text
/mnt/backup/media
```

Example layout:

```text
/mnt/backup/media
├── movies/
├── tv/
└── music/
```

The Plex LXC accesses media storage through a Proxmox mount point.

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
systemctl status plexmediaserver
```

### Restart Plex

```bash
systemctl restart plexmediaserver
```

### Stop Plex

```bash
systemctl stop plexmediaserver
```

### Start Plex

```bash
systemctl start plexmediaserver
```

## Access

Internal:

```text
http://192.0.2.22:32400/web
```

External:

```text
https://plex.example.com
```

Verify:

- Web interface loads
- Media libraries are available
- Users can authenticate
- Playback works

## Hardware Transcoding

Plex uses the Intel iGPU for hardware-accelerated transcoding.

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

## Plex Configuration

The primary Plex configuration location is:

```text
/var/lib/plexmediaserver
```

This contains:

- Library database
- Metadata
- User preferences
- Server settings
- Plugins

## Updating Plex

Update package lists:

```bash
apt update
```

Upgrade installed packages:

```bash
apt upgrade
```

Restart Plex:

```bash
systemctl restart plexmediaserver
```

Verify:

```bash
systemctl status plexmediaserver
```

## Backup

The Plex backup includes:

- Plex database
- Server configuration
- Metadata
- Preferences

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

Restore the Plex LXC from Proxmox backup.

Verify:

```bash
pct list
```

### 2. Restore Plex Configuration

Restore:

```text
/var/lib/plexmediaserver
```

Ensure ownership is correct:

```bash
chown -R plex:plex /var/lib/plexmediaserver
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

Verify Plex can access the GPU device.

### 5. Start Plex

```bash
systemctl start plexmediaserver
```

### 6. Validate Service

Verify:

- Web interface loads
- Libraries appear
- Media playback works
- Hardware transcoding functions

## Troubleshooting

### Plex Won't Start

Check service status:

```bash
systemctl status plexmediaserver
```

View logs:

```bash
journalctl -u plexmediaserver -f
```

### Media Libraries Missing

Verify storage:

```bash
ls /media
```

Confirm:

- Storage is mounted.
- Permissions are correct.
- Library paths are unchanged.

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

Check Plex dashboard: **Settings → Dashboard → Now Playing**

Confirm:

- Transcoding is active.
- Hardware acceleration is being used.

## Maintenance Checklist

### Weekly

- [ ] Verify Plex is running
- [ ] Check storage availability
- [ ] Review logs for errors
- [ ] Verify media libraries scan correctly

### Monthly

- [ ] Update Plex packages
- [ ] Verify hardware acceleration
- [ ] Review metadata storage usage
- [ ] Confirm backups are completing

### Quarterly

- [ ] Test Plex restore procedure
- [ ] Verify media storage health
- [ ] Review library organization
- [ ] Update documentation
