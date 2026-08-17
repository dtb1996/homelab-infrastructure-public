# Maintenance

## Overview

This document outlines the routine maintenance tasks required to keep the homelab secure, reliable, and operating efficiently.

Maintenance is divided into daily, weekly, monthly, quarterly, and as-needed tasks.

## Daily Tasks

### Verify Backup Status

- Review Home Assistant backup dashboard.
- Confirm the nightly backup completed successfully.
- Check for failed backup jobs.

### Review Uptime Monitoring

- Check Uptime Kuma for outages.
- Investigate any service interruptions.

### Review Notifications

Check for:

- Failed backups
- Service outages
- Hardware alerts

Estimated time: **5 minutes**

## Weekly Tasks

### Update Containers

Update all Docker containers.

Example:

```bash
docker compose pull
docker compose up -d
```

### Update Linux Packages

Update each LXC.

```bash
apt update
apt upgrade
```

### Update Proxmox

```bash
apt update
apt full-upgrade
```

Reboot only if required.

### Review Disk Usage

Proxmox:

```bash
df -h
```

Docker:

```bash
docker system df
```

Review:

- SSD utilization
- HDD utilization
- USB backup utilization

### Verify Backup Logs

Review:

```text
/srv/backups/logs
```

Look for:

- Errors
- Failed backups
- Missing archives

### Check Git Repository

Push any infrastructure changes.

Review:

- Documentation
- Scripts
- Configuration changes

Commit outstanding changes.

Estimated time: **15–30 minutes**

## Monthly Tasks

### Verify Restore Procedures

Perform a test restore for one service.

Examples:

- Home Assistant
- Paperless
- Docker configuration

Document any issues.

### SMART Disk Health

Review SMART data.

Example:

```bash
smartctl -a /dev/sda
smartctl -a /dev/sdb
smartctl -a /dev/sdd
```

Review:

- Reallocated sectors
- Pending sectors
- Temperature
- Overall health

### Review Storage Usage

Verify:

- SSD free space
- HDD free space
- Backup capacity

Archive or remove unnecessary data.

### Review Reverse Proxy

Verify:

- All hostnames resolve
- HTTPS certificates renew correctly
- No broken routes

### Review Documentation

Update:

- `services.md`
- `network.md`
- `storage.md`
- `reverse-proxy.md`

Document any infrastructure changes.

Estimated time: **30–60 minutes**

## Quarterly Tasks

### Test Disaster Recovery

Walk through the disaster recovery documentation.

Verify:

- Backup locations
- Recovery procedures
- Documentation accuracy

### Offline Backup

Mount the secondary USB drive.

Synchronize `/mnt/backup` to the offline backup drive using `rsync`.

After synchronization:

- Verify copied files
- Unmount the drive
- Disconnect the drive

### Audit Services

Review:

- Running containers
- Running LXCs
- DNS records
- Reverse proxy entries
- Homepage entries

Remove unused services.

### Review Security

Check for:

- OS updates
- Container updates
- Caddy updates
- Cloudflare configuration
- SSH configuration

Review exposed services.

Estimated time: **1–2 hours**

## As Needed

### Add a New Service

When deploying a new service:

- Deploy the application
- Configure storage
- Configure backups
- Configure Caddy
- Verify HTTPS
- Add to Homepage
- Update documentation
- Commit configuration to Git

### Replace Hardware

When replacing hardware:

- Update documentation
- Verify backups
- Test restores
- Update inventory

### Infrastructure Changes

Whenever changes are made:

- Update documentation
- Commit to Git
- Push to GitHub

## Maintenance Checklist

### Daily

- [ ] Verify backups
- [ ] Check Uptime Kuma
- [ ] Review notifications

### Weekly

- [ ] Update Docker containers
- [ ] Update LXCs
- [ ] Update Proxmox
- [ ] Review storage usage
- [ ] Check backup logs
- [ ] Push Git changes

### Monthly

- [ ] Test a restore
- [ ] Review SMART health
- [ ] Review storage utilization
- [ ] Verify reverse proxy
- [ ] Update documentation

### Quarterly

- [ ] Sync offline USB backup
- [ ] Test disaster recovery
- [ ] Audit services
- [ ] Review security

## Maintenance Philosophy

The homelab is maintained using the following principles:

- Automate repetitive tasks whenever possible.
- Version control all infrastructure changes.
- Maintain multiple verified backups.
- Document every significant infrastructure change.
- Test recovery procedures regularly.
- Prefer incremental improvements over major changes.
- Keep services and documentation synchronized.
