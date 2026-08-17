# Network

## Overview

The homelab operates on a single LAN behind the primary router. Services are hosted on Proxmox containers and are accessed internally through local IP addresses or externally through Cloudflare DNS and Caddy reverse proxy.

### Network Diagram

```text
Internet
    |
    |
Cloudflare DNS
    |
    |
Router (TP-Link Archer AXE75)
    |
    |
192.0.2.1/24 Network
    |
    +-----------------------------+
    |                             |
Proxmox Host                 Raspberry Pi
192.0.2.10                 192.0.2.50
    |                             |
    |                        AdGuard Secondary
    |                        Uptime Kuma
    |
    |
LXC Containers
    |
    +-- Docker LXC
    |      |
    |      +-- Homepage
    |      +-- Portainer
    |      +-- Samba
    |      +-- Paperless
    |
    +-- Jellyfin LXC
    |
    +-- Plex LXC
    |
    +-- AdGuard Home LXC
    |
    +-- Proxy LXC
    |      |
    |      +-- Caddy Reverse Proxy
    |
    +-- Immich LXC
    |
    +-- Home Assistant LXC
    |
    +-- Syncthing LXC
```

## Network Information

### Local Network

| Item         | Value                |
| ------------ | -------------------- |
| Network      | `192.0.2.1/24`     |
| Router       | TP-Link Archer AXE75 |
| DNS Provider | AdGuard Home         |
| Domain       | `example.com`    |

## Infrastructure Hosts

| Host         | IP Address      | Purpose                      |
| ------------ | --------------- | ---------------------------- |
| Proxmox      | `192.0.2.10`  | Hypervisor and LXC host      |
| Raspberry Pi | `192.0.2.50` | Secondary DNS and monitoring |

## Proxmox Containers

| CT ID | Name           | Purpose                        |
| ----- | -------------- | ------------------------------ |
| 100   | docker         | Docker services                |
| 101   | jellyfin       | Media server                   |
| 102   | plex           | Media server                   |
| 110   | adguard-home   | Primary DNS filtering          |
| 120   | proxy          | Reverse proxy                  |
| 121   | syncthing      | File sync                      |
| 131   | immich         | Image backup and media server  |
| 120   | home-assistant | Smart home automation platform |

## DNS

### Primary DNS

AdGuard Home provides network-wide DNS filtering.

Primary DNS:

```text
192.0.2.30
```

Services:

- Ad blocking
- Local DNS resolution
- Homelab hostname resolution

### Secondary DNS

A Raspberry Pi runs a secondary AdGuard Home instance.

Purpose:

- DNS redundancy
- Maintain network access if Proxmox is unavailable

## Domain Routing

External services use the domain:

```text
example.com
```

DNS is managed through Cloudflare.

Traffic flow:

```text
Client
  |
  |
Cloudflare DNS
  |
  |
Caddy Reverse Proxy
  |
  |
Internal Service
```

## Reverse Proxy

Caddy runs in the proxy LXC and provides:

- HTTPS termination
- Automatic TLS certificates
- Reverse proxy routing

Current external services:

| Hostname                   | Destination    |
| -------------------------- | -------------- |
| homepage.example.com   | Homepage       |
| portainer.example.com  | Portainer      |
| paperless.example.com  | Paperless      |
| jellyfin.example.com   | Jellyfin       |
| plex.example.com       | Plex           |
| photos.example.com     | Immich         |
| adguard.example.com    | AdGuard Home   |
| adguard-pi.example.com | AdGuard Pi     |
| ha.example.com         | Home Assistant |
| status.example.com     | Uptime Kuma    |
| sync.example.com       | Syncthing      |

## Storage Network Access

Shared storage is provided through:

- USB storage attached to Proxmox Host machine

Samba provides network file access:

```text
\\192.0.2.20
```

Used for:

- Cross-platform file access
- Document imports
- Media management

## Network Services

| Service      | Role                          |
| ------------ | ----------------------------- |
| Router       | DHCP, NAT, Internet gateway   |
| AdGuard Home | DNS filtering                 |
| Cloudflare   | Public DNS and TLS validation |
| Caddy        | Reverse proxy                 |
| Uptime Kuma  | Service monitoring            |

## Future Network Improvements

Potential future changes:

- Add VLAN segmentation
- Separate IoT devices from trusted devices
- Add dedicated managed switch
- Upgrade to 10Gb networking for storage
- Add firewall rules between service groups
- Add dedicated NAS storage network
