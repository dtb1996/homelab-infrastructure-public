# Public Repository Sanitization Checklist

## Network

- [ ] Private IPv4 addresses removed
- [ ] IPv6 addresses removed
- [ ] MAC addresses removed
- [ ] Router information sanitized
- [ ] DNS names sanitized
- [ ] Tailscale information removed

## Identity

- [ ] Personal email addresses removed
- [ ] Personal usernames removed where appropriate
- [ ] Hostnames sanitized
- [ ] Personal domain removed

## Secrets

- [ ] Passwords removed
- [ ] API tokens removed
- [ ] SSH keys removed
- [ ] `.env` contents removed
- [ ] Cloudflare credentials removed

## Generated Data

- [ ] Backup archives removed
- [ ] Database dumps removed
- [ ] Logs reviewed
- [ ] Docker inspect output reviewed
- [ ] Docker compose rendered configs reviewed
- [ ] Inventory files reviewed

## Git

- [ ] `git remote -v` points only to public repository
- [ ] `git log` contains no sensitive commits
- [ ] `git grep` checked for personal information
- [ ] Working tree reviewed before push

## Searches

### MAC addresses

```bash
grep -RniE '([0-9a-f]{2}[:-]){5}[0-9a-f]{2}' .
```

### IPv4 addresses

```bash
grep -RniE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' .
```

#### Email addresses

```bash
grep -RniE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' .
```

#### Common domain references

```bash
grep -RniE '\.(com|net|org|home|local)\b' .
```

## Initial Copy and Clear Git History

```bash
cp -r homelab-infrastructure homelab-infrastructure-public

cd homelab-infrastructure-public

rm -rf .git

git init

git add .

git commit -m "Initial public release"
```
