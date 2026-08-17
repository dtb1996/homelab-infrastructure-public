# Homelab Architecture

## Host

Proxmox VE

Hardware:

- Lenovo T450s
- Intel i7-5600U
- 8GB RAM

Storage:

- SSD: Proxmox + VM/LXC storage
- HDD: backups, ISOs, bulk data
- USB: secondary backup target

## Containers

| ID  | Name           | Purpose                 |
| --- | -------------- | ----------------------- |
| 100 | docker         | Docker services         |
| 101 | jellyfin       | Media server            |
| 102 | plex           | Media server            |
| 110 | adguard        | DNS filtering           |
| 120 | proxy          | Caddy reverse proxy     |
| 121 | syncthing      | File sync               |
| 131 | immich         | Image backup storage    |
| 140 | home-assistant | Home Assistant services |
