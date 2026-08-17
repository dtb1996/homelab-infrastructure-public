# AdGuard Home Runbook

## Overview

This runbook documents the operation, maintenance, backup, and recovery procedures for the AdGuard Home DNS infrastructure.

The homelab uses **two independent AdGuard Home instances**:

- **Primary:** Dedicated Proxmox LXC (CT110)
- **Secondary:** Raspberry Pi

The primary instance handles normal DNS resolution for the network, while the Raspberry Pi provides redundancy if the primary DNS server becomes unavailable.

## DNS Architecture

```text
                Client Devices
          ┌───────────┴───────────┐
          ▼                       ▼
    Primary DNS             Secondary DNS
    AdGuard Home            Raspberry Pi
        CT110               AdGuard Home
```

## Instances

| Instance  | Location                 | Purpose              |
| --------- | ------------------------ | -------------------- |
| Primary   | AdGuard Home LXC (CT110) | Primary DNS server   |
| Secondary | Raspberry Pi             | Redundant DNS server |

## Responsibilities

AdGuard Home is responsible for:

- Network-wide DNS resolution
- Ad blocking
- DNS filtering
- DNS rewrites
- Local DNS records
- DNS query logging
- Providing redundant DNS services

## Dependencies

AdGuard Home depends on:

- Proxmox VE (Primary)
- Raspberry Pi (Secondary)
- Local network connectivity
- Internet connectivity
- Cloudflare (optional upstream)
- Client DNS configuration

## Access

### Primary

Internal:

```text
http://192.0.2.30:3000
```

External:

```text
https://adguard.example.com
```

### Secondary

Internal:

```text
http://192.0.2.50:3000
```

External:

```text
https://adguard-pi.example.com
```

## Service Management (Primary)

Check status:

```bash
systemctl status AdGuardHome
```

Start:

```bash
systemctl start AdGuardHome
```

Stop:

```bash
systemctl stop AdGuardHome
```

Restart:

```bash
systemctl restart AdGuardHome
```

Enable on boot:

```bash
systemctl enable AdGuardHome
```

## Configuration

Primary configuration directory:

```text
/opt/AdGuardHome
```

Important files include:

| File               | Purpose                             |
| ------------------ | ----------------------------------- |
| `AdGuardHome.yaml` | Primary configuration               |
| `data/`            | Runtime data and filter information |

## Health Checks

Verify the service is running:

```bash
systemctl status AdGuardHome
```

Verify DNS resolution:

```bash
dig google.com
```

Test a blocked domain:

```bash
dig doubleclick.net
```

Verify the web interface is accessible.

Confirm:

- Query log updates
- Clients appear
- Filters are active

## Updating AdGuard Home

Stop the service:

```bash
systemctl stop AdGuardHome
```

Install the latest release following the official upgrade procedure.

Restart:

```bash
systemctl start AdGuardHome
```

Verify:

```bash
systemctl status AdGuardHome
```

Confirm the dashboard loads successfully.

## Backup

Nightly backups include:

- AdGuard Home configuration
- DNS settings
- Custom DNS rewrites
- Filters
- Allowlists
- Blocklists

Backup location:

```text
/srv/backups
```

Verify backup logs:

```text
/srv/backups/logs
```

## Recovery Procedure (Primary)

### 1. Restore the LXC

Restore the AdGuard Home LXC from the latest Proxmox backup.

Verify:

```bash
pct list
```

### 2. Restore Configuration

Restore:

```text
/opt/AdGuardHome
```

Verify:

```bash
ls /opt/AdGuardHome
```

### 3. Start the Service

```bash
systemctl start AdGuardHome
```

### 4. Verify DNS

Run:

```bash
dig google.com
```

Verify:

- DNS resolution
- Query logging
- Filters
- Local DNS entries
- DNS rewrites

## Recovery Procedure (Secondary Raspberry Pi)

If the Raspberry Pi is rebuilt:

1. Install Raspberry Pi OS.
2. Restore the AdGuard Home configuration backup.
3. Start AdGuard Home.
4. Verify the web interface.
5. Confirm DNS resolution.
6. Confirm clients can use the secondary server.

## Troubleshooting

### Service Won't Start

Check:

```bash
systemctl status AdGuardHome
```

View logs:

```bash
journalctl -u AdGuardHome -f
```

### DNS Not Resolving

Test upstream DNS:

```bash
dig google.com @1.1.1.1
```

Test local server:

```bash
dig google.com @127.0.0.1
```

Verify upstream DNS servers are configured correctly.

### Clients Not Using AdGuard

Verify client DNS settings.

Confirm:

- Primary DNS points to the AdGuard LXC.
- Secondary DNS points to the Raspberry Pi.

### Dashboard Unavailable

Verify:

```bash
systemctl status AdGuardHome
```

Check firewall rules.

Verify the reverse proxy configuration if accessing externally.

### Blocklists Not Updating

Verify:

- Internet connectivity
- Filter update settings
- DNS resolution from the server itself

Attempt a manual filter update from the dashboard.

## Maintenance Checklist

### Weekly

- [ ] Verify both DNS servers are online
- [ ] Review blocked query statistics
- [ ] Confirm filter updates completed
- [ ] Verify DNS rewrites

### Monthly

- [ ] Update AdGuard Home
- [ ] Review custom DNS entries
- [ ] Remove unused clients
- [ ] Verify backups

### Quarterly

- [ ] Test failover using the secondary DNS server
- [ ] Verify Raspberry Pi backup
- [ ] Review filtering performance
- [ ] Update documentation

## Verification Checklist

After maintenance or recovery, verify:

- [ ] Primary AdGuard Home is operational.
- [ ] Secondary AdGuard Home is operational.
- [ ] DNS resolution is working.
- [ ] Ad blocking is functioning.
- [ ] Custom DNS rewrites resolve correctly.
- [ ] External dashboards are accessible.
- [ ] Backup jobs complete successfully.
