# Raspberry Pi Runbook

## Overview

This runbook documents the operation, maintenance, backup, and recovery procedures for the Raspberry Pi infrastructure node.

The Raspberry Pi provides redundant network services for the homelab, including:

- Secondary AdGuard Home DNS service
- Uptime Kuma monitoring
- Remote access through Tailscale
- Backup source for Raspberry Pi configuration data

The Raspberry Pi runs independently from the Proxmox environment to provide redundancy for critical network services.

## Host Information

| Property           | Value                        |
| ------------------ | ---------------------------- |
| Hostname           | `pi-adguard`                 |
| Operating System   | Debian GNU/Linux 13 (trixie) |
| Architecture       | ARM64 (`aarch64`)            |
| Kernel             | Linux 6.18.34+rpt-rpi-v8     |
| Primary Interface  | `wlan0`                      |
| Primary IP Address | `192.0.2.50`              |
| Tailscale IP       | `100.89.108.18`              |

Verify system information:

```bash
hostnamectl
uname -a
cat /etc/os-release
```

## Network Configuration

### IP Address

The Raspberry Pi currently receives its address through DHCP:

```text
192.0.2.50/24
```

Verify:

```bash
ip addr
ip route
hostname -I
```

### DNS

DNS configuration is managed by Tailscale.

Current configuration:

```text
/etc/resolv.conf
```

Example:

```text
nameserver 100.100.100.100
nameserver fd7a:115c:a1e0::53
```

Do not manually edit this file.

Tailscale regenerates the file automatically.

Verify:

```bash
cat /etc/resolv.conf
```

## Responsibilities

The Raspberry Pi provides:

- Secondary DNS availability
- DNS filtering
- Network monitoring
- Remote administration access
- Backup source for Raspberry Pi configuration

## Services

Active services:

```bash
systemctl --type=service --state=running
```

Important services:

| Service        | Purpose                                    |
| -------------- | ------------------------------------------ |
| AdGuardHome    | DNS filtering and recursive DNS forwarding |
| Docker         | Container runtime                          |
| Uptime Kuma    | Service monitoring                         |
| Tailscale      | Remote access                              |
| SSH            | Administration                             |
| NetworkManager | Network management                         |

## AdGuard Home

AdGuard Home runs directly on the Raspberry Pi as a native systemd service. It is not deployed using Docker.

Responsibilities:

- DNS filtering
- Secondary DNS availability
- Network-level blocking
- DNS query management

### Installation Layout

| Path                                | Purpose                  |
| ----------------------------------- | ------------------------ |
| `/opt/AdGuardHome`                  | Application directory    |
| `/opt/AdGuardHome/AdGuardHome`      | Executable               |
| `/opt/AdGuardHome/AdGuardHome.yaml` | Configuration            |
| `/opt/AdGuardHome/data`             | Runtime data             |
| `/opt/AdGuardHome/agh-backup`       | AdGuard internal backups |

Verify:

```bash
ls -lah /opt/AdGuardHome
```

### Service Management

Check status:

```bash
systemctl status AdGuardHome
```

Restart:

```bash
sudo systemctl restart AdGuardHome
```

Stop:

```bash
sudo systemctl stop AdGuardHome
```

Start:

```bash
sudo systemctl start AdGuardHome
```

View logs:

```bash
journalctl -u AdGuardHome
```

Follow logs:

```bash
journalctl -u AdGuardHome -f
```

### Ports

AdGuard Home listens on:

| Port       | Purpose            |
| ---------- | ------------------ |
| 53 TCP/UDP | DNS                |
| 3000 TCP   | Web administration |

Verify:

```bash
ss -tulpn | grep AdGuard
```

Expected:

```text
_:53
_:3000
```

### Access

Internal:

```text
http://192.0.2.50:3000
```

External:

```text
https://adguard-pi.example.com
```

Reverse proxy:

```text
adguard-pi.example.com {
    reverse_proxy 192.0.2.50:3000
}
```

Verify:

- Dashboard loads
- DNS queries appear
- Filtering works
- Client statistics update

## Uptime Kuma

Uptime Kuma runs as a Docker container.

Purpose:

- Service monitoring
- Availability tracking
- Homelab health checks

### Container Information

| Property       | Value                    |
| -------------- | ------------------------ |
| Container Name | `uptime-kuma`            |
| Image          | `louislam/uptime-kuma:1` |
| Port           | `3001`                   |
| Data Directory | `/root/uptime-kuma`      |

Verify:

```bash
docker ps
```

### Docker Management

View container:

```bash
docker ps --filter name=uptime-kuma
```

Restart:

```bash
docker restart uptime-kuma
```

View logs:

```bash
docker logs uptime-kuma
```

Follow logs:

```bash
docker logs -f uptime-kuma
```

### Storage

Uptime Kuma data:

```text
/root/uptime-kuma
```

Docker mount:

```text
/root/uptime-kuma:/app/data
```

Verify:

```bash
ls -lah /root/uptime-kuma
```

### Access

Internal:

```text
http://192.0.2.50:3001
```

External:

```text
https://status.example.com
```

Reverse proxy:

```text
status.example.com {
    reverse_proxy 192.0.2.50:3001
}
```

## Storage Layout

The Raspberry Pi uses the SD card as its primary storage.

Verify:

```bash
lsblk
df -h
```

Current layout:

| Device           | Purpose         |
| ---------------- | --------------- |
| `/dev/mmcblk0p1` | Boot partition  |
| `/dev/mmcblk0p2` | Root filesystem |

## Backup Architecture

The Raspberry Pi backup process uses a two-stage model.

### Stage 1 - Raspberry Pi

The Raspberry Pi creates local backups:

```text
/root/backups/raspberrypi
```

Structure:

```text
/root/backups/raspberrypi
├── archives
├── inventories
├── latest
└── logs
```

### Stage 2 - Proxmox Pull Backup

The Proxmox host pulls backups over SSH.

Backup script:

```text
/srv/homelab-git/scripts/backup/backup-raspberrypi.sh
```

Configuration:

```text
PI_HOST="192.0.2.50"
REMOTE_DIR="/root/backups/raspberrypi"
```

Destination:

```text
/srv/backups/raspberrypi
```

### Backup Contents

Backups include:

- Raspberry Pi configuration archives
- Inventories
- Checksums
- Logs

Inventory snapshots include:

- Host information
- OS information
- Disk usage
- Memory usage
- Running services
- Firmware information

### Backup Verification

On Proxmox:

Check backups:

```bash
ls -lah /srv/backups/raspberrypi
```

Verify latest backup:

```bash
ls -lah /srv/backups/raspberrypi/latest
```

Review logs:

```bash
cat /srv/backups/raspberrypi/logs/raspberrypi-backup.log
```

## Recovery Procedure

### 1. Restore Raspberry Pi Operating System

If the SD card fails:

1. Flash Debian Raspberry Pi image to a replacement SD card.
2. Boot the Raspberry Pi.
3. Configure network access.
4. Enable SSH.
5. Restore required services.

Verify connectivity:

```bash
ssh root@192.0.2.50
```

### 2. Restore AdGuard Home

Install AdGuard Home:

```bash
mkdir -p /opt/AdGuardHome
```

Restore:

```text
/opt/AdGuardHome
```

Required files:

- `AdGuardHome`
- `AdGuardHome.yaml`
- `data/`

Restore systemd service:

```text
/etc/systemd/system/AdGuardHome.service
```

Reload systemd:

```bash
systemctl daemon-reload
```

Enable service:

```bash
systemctl enable AdGuardHome
```

Start:

```bash
systemctl start AdGuardHome
```

Verify:

```bash
systemctl status AdGuardHome
```

Test DNS:

```bash
nslookup google.com 192.0.2.50
```

### 3. Restore Uptime Kuma

Install Docker:

```bash
apt update
apt install docker.io
```

Restore data:

```text
/root/uptime-kuma
```

Recreate container:

```bash
docker run -d \
--name uptime-kuma \
--restart unless-stopped \
-p 3001:3001 \
-v /root/uptime-kuma:/app/data \
louislam/uptime-kuma:1
```

Verify:

```bash
docker ps
```

### 4. Restore Tailscale

Install Tailscale:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

Authenticate:

```bash
tailscale up
```

Verify:

```bash
tailscale status
```

### 5. Restore Reverse Proxy Access

Verify the Caddy configuration on the proxy container:

AdGuard:

```text
adguard-pi.example.com
```

Target:

```text
192.0.2.50:3000
```

Uptime Kuma:

```text
status.example.com
```

Target:

```text
192.0.2.50:3001
```

Restart Caddy:

```bash
systemctl restart caddy
```

## Troubleshooting

### AdGuard Home Not Running

Check:

```bash
systemctl status AdGuardHome
```

Logs:

```bash
journalctl -u AdGuardHome
```

Verify ports:

```bash
ss -tulpn | grep :53
```

### DNS Resolution Problems

Check:

```bash
nslookup google.com 192.0.2.50
```

Verify AdGuard logs:

```bash
journalctl -u AdGuardHome -f
```

### Uptime Kuma Not Available

Check container:

```bash
docker ps
```

Restart:

```bash
docker restart uptime-kuma
```

Logs:

```bash
docker logs uptime-kuma
```

## Maintenance Checklist

### Weekly

- [ ] Verify AdGuard Home is responding
- [ ] Verify DNS filtering works
- [ ] Confirm Uptime Kuma is running
- [ ] Review backup logs

### Monthly

- [ ] Update Debian packages
- [ ] Update AdGuard Home
- [ ] Update Docker images
- [ ] Verify available storage

### Quarterly

- [ ] Test Raspberry Pi recovery
- [ ] Verify backup restoration
- [ ] Review SD card health
- [ ] Review service documentation

## Verification Checklist

After maintenance or recovery:

- [ ] Raspberry Pi boots successfully
- [ ] SSH access works
- [ ] Tailscale connection works
- [ ] AdGuard Home service is running
- [ ] DNS queries resolve
- [ ] Filtering works
- [ ] Uptime Kuma container is healthy
- [ ] Reverse proxy access works
- [ ] Backups complete successfully
