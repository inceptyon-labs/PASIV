---
name: uranus-deploy
description: Deploy a service to the Unraid home server (Uranus) or onboard a new one. Build-from-source docker compose, pushed from the Mac over SSH with `deploy`; no registry, no GitHub Actions, no GitHub credentials on the box. Use for "deploy to uranus", "deploy <service>", "put this on unraid", "redeploy the dashboard", "add a new service to uranus", "is <service> up on uranus".
user-invocable: true
allowed-tools: Bash Read Grep Glob Edit Write
---

# Uranus deploy

One pattern for every self-hosted service on Uranus. The Mac is the source of truth; the box
only builds and runs.

## Host config (read first)

Host details stay out of this repo. Read `.env` next to this `SKILL.md` before running anything:

| Variable | Meaning |
|---|---|
| `URANUS_HOST` | LAN address of the box |
| `URANUS_SSH` | SSH target, `user@host` |
| `URANUS_GIT_ROOT` | Directory on the box that holds the bare git repos |
| `URANUS_INVENTORY` | Private file listing the services on this pattern, their ports, reference compose files and FolderView3 folders |
| `URANUS_DEPLOY_SRC` | Local source of truth for the box's `deploy.sh` |

Substitute the values into the commands below, or source the file in the same command
(`set -a; . <skill-dir>/.env; set +a; ssh "$URANUS_SSH" ...`); shell state does not carry
between calls. If `.env` is missing, copy `.env.example` to `.env` and ask the user for the
values. Never write these values into this skill or into any public file.

Read `$URANUS_INVENTORY` before deploying a known service; its entry records the port and any
quirks (sidecars, override networks, deploy timing).

## How it works

```
Mac: git archive HEAD  ──ssh──▶  Uranus: /mnt/user/appdata/<name>-src
                                          ├─ docker-compose.yml   (from the repo)
                                          ├─ .env                 (per-host, preserved)
                                          ├─ docker-compose.override.yml (per-host wiring, preserved)
                                          └─ data/                (bind-mounted state, preserved)
                                 then: docker compose up -d --build
```

- **Mac command:** `~/bin/deploy [name]` (name defaults to the repo directory). Ships committed
  `HEAD` only. `/acp` runs it automatically after pushing `main` when the repo has a `.deploy` marker file. `deploy --list`, `deploy --status [name]`, `deploy --up <name>` (rebuild without
  shipping).
- **Box script:** `bash /boot/config/scripts/deploy.sh {receive|up|status|list}`. Lives on the
  flash drive so it survives reboots; must be invoked via `bash` (flash is noexec). Log:
  `/mnt/user/appdata/deploy.log`. Each `<name>-src/.deployed` records the rev and time.
- **Icons.** After `up`, `deploy.sh` seeds `/var/lib/docker/unraid/images/<name>-icon.png` from the repo's `unraid-icon.png`, else from the icon label URL, and warns when neither exists.
  Unraid 7.3.1 only reads that cache for a container that has a `net.unraid.docker.icon` label:
  with no label it shows a grey "?" even when the cached file is there. Every container needs the
  label, sidecars included.
- **Compose owns the container.** A container created in the Unraid Docker UI (dockerman) with
  the same `container_name` is evicted once by `deploy.sh` so compose can take over. Containers
  still show in the Unraid UI via the `net.unraid.docker.webui` / `.icon` labels.

## Deploy an existing service

```bash
cd ~/Development/<repo> && deploy            # after committing (or after /acp)
deploy --status <name>                       # compose ps on the box
curl -s -o /dev/null -w '%{http_code}\n' http://$URANUS_HOST:<port>/
```

If the build fails, the previous container keeps running (compose only swaps on success).
Read the tail of `deploy.log` or `ssh $URANUS_SSH 'cd /mnt/user/appdata/<name>-src && docker compose logs --tail 50'`.

## Onboard a new service

1. **Compose file in the repo** (`docker-compose.yml`, committed). Conventions; copy from one
   of the reference compose files listed in `$URANUS_INVENTORY`:
   - `build: .` and an explicit `container_name` (same as the service and the repo name).
   - `restart: unless-stopped`.
   - Host port from `.env` with a default: `"${NAME_PORT:-8787}:8787"`.
   - Secrets as `${VAR:?set VAR in .env}`; optional values as `${VAR:-}`.
   - Unraid labels on every service: `net.unraid.docker.webui: "http://[IP]:[PORT:<port>]/"`
     (a path that returns a page; API-only servers point at their health route) and
     `net.unraid.docker.icon`. The icon label is required, not optional. Use a URL that resolves:
     public GitHub repo `https://raw.githubusercontent.com/<owner>/<repo>/main/unraid-icon.png`;
     private or bare-repo-only `http://$URANUS_HOST:<cgit-port>/<repo>/plain/unraid-icon.png`
     (cgit; its port is in the inventory).
   - `unraid-icon.png` (square, 512px) at the repo root. `deploy.sh` copies it into Unraid's icon
     cache on every deploy. The cache is only used when the icon label is present; without the
     label Unraid shows a grey "?" whatever is cached.
   - Persistent state under `./data/...` or `/mnt/user/appdata/<name>` bind mounts, never
     anonymous volumes.
   - Optional bundled dependencies (a database) behind `profiles:` with `COMPOSE_PROFILES`
     in `.env.example` so `docker compose up -d --build` works on any host.
   - Add `docker-compose.override.yml`, `compose.override.yml`, `data/`, `.env` to `.gitignore`.
2. **Pick a free host port.** `ssh $URANUS_SSH 'docker ps --format "{{.Ports}}"' | grep -oE '0.0.0.0:[0-9]+' | sort -u`.
3. **Per-host files on the box** (never commit these):
   ```bash
   ssh $URANUS_SSH 'mkdir -p /mnt/user/appdata/<name>-src && cat > /mnt/user/appdata/<name>-src/.env <<EOF
   NAME_PORT=<port>
   SOME_SECRET=$(openssl rand -hex 32)
   EOF
   chmod 600 /mnt/user/appdata/<name>-src/.env'
   ```
   Need the Nginx Proxy Manager network? Add `docker-compose.override.yml` there:
   ```yaml
   services:
     <name>:
       networks: [npm]
   networks:
     npm:
       external: true
   ```
4. **Auto-deploy on `/acp`:** commit a `.deploy` file at the repo root containing the service name (or leave it empty for the repo directory name). `/acp` and `/acpd` run `deploy` after a successful push to `main`.
5. **First deploy:** `cd ~/Development/<repo> && git add -A && git commit -m "chore(deploy): compose file" && deploy`.
6. **Verify:** `deploy --status <name>` and curl the port. Check the Unraid Docker tab shows
   it with icon and WebUI link. File it in a FolderView3 folder: add the label
   `folder.view3: "<Folder Name>"` to the compose service, or add the container name to a
   folder's `containers` list in `/boot/config/plugins/folder.view3/docker.json` (folder names
   are in the inventory); otherwise it sits unfiled below the folders.
7. **Record it:** add the service to `$URANUS_INVENTORY` with its port and quirks. Never add
   it to this file.

## Migrating a dockerman-created container

Capture its env first so nothing is lost, then let `deploy.sh` evict it:

```bash
ssh $URANUS_SSH 'docker inspect <name> --format "{{range .Config.Env}}{{println .}}{{end}}" | grep -vE "^(PATH|HOST_|NODE_|YARN_)" > /mnt/user/appdata/<name>-src/.env; chmod 600 /mnt/user/appdata/<name>-src/.env'
ssh $URANUS_SSH 'docker inspect <name> --format "{{json .HostConfig.PortBindings}} {{range \$k,\$v := .NetworkSettings.Networks}}{{\$k}} {{end}} {{range .Mounts}}{{.Source}}:{{.Destination}} {{end}}"'
```

Ports go into `.env`, non-default networks into the override file, bind mounts into the compose
file. If the old container used a hand-made network that the compose file now declares by
`name:`, remove it first (`docker network rm <net>`) or compose refuses to adopt it.

## Rules

- Never store secrets in the repo or paste them into chat; create `.env` on the box with a
  heredoc or `docker inspect` redirect.
- Never `docker pull` a registry image for these services; the image is built from the shipped
  tree. There is no GitHub Actions publish step and none should be added.
- Deploy only committed work. If `deploy` warns about uncommitted changes, commit (or `/acp`)
  first.
- Do not edit `/boot/config/scripts/deploy.sh` on the box directly; the source of truth is
  `$URANUS_DEPLOY_SRC` (copy there on change, then `scp` it over).
