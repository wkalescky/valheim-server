# valheim-server

ECS-hosted Valheim dedicated server with S3-backed world saves and optional Cloudflare DNS registration. Each world runs as an on-demand Fargate task; the server shuts itself down after a configurable idle period and syncs saves back to S3 before exiting.

## Quick start

```sh
# Deploy infrastructure
make plan   # preview
make apply  # create ECS cluster, S3 bucket, IAM roles, etc.

# Launch a world
make start WORLD=myworld
```

`make start` resolves cluster/subnet/security-group from Terraform outputs automatically.

---

## Environment Variables

Variable names and values are case-sensitive.

### Required

These must be present or the container exits immediately.

| Name | Defined in | Purpose |
| --- | --- | --- |
| `S3_BUCKET` | ECS task definition (set by Terraform to the auto-created bucket) | S3 bucket used for world saves, backups, and per-world `server.env` |
| `WORLD` | `make start WORLD=<name>` (injected as ECS container override) or `.env` for local Docker | World identifier; used as the S3 key prefix (`s3://$S3_BUCKET/$WORLD/`) and as the Cloudflare DNS label |
| `SERVER_PASSWORD` | `s3://$S3_BUCKET/$WORLD/server.env` | Valheim join password — minimum 5 characters |

### Server configuration

Loaded from `s3://$S3_BUCKET/$WORLD/server.env` by `world_bootstrap.sh` at startup. Use a `KEY=VALUE` file (see `docker/ecs/test/*/server.env` for examples).

| Name | Default | Defined in | Purpose |
| --- | --- | --- | --- |
| `SERVER_NAME` | `My server` | `server.env` | Display name shown in the server browser |
| `SERVER_PORT` | `2456` | `server.env` | UDP base port; Valheim also uses `+1` and `+2` |
| `SERVER_WORLD` | `Dedicated` | `server.env` | World file name without `.db`/`.fwl` extension |
| `SERVER_PUBLIC` | `0` | `server.env` | `1` = listed publicly in server browser; `0` = unlisted |

### Save & backup

Controlled by `save_manager.sh`, which runs as a supervisor process alongside the server.

| Name | Default | Defined in | Purpose |
| --- | --- | --- | --- |
| `SAVE_INTERVAL_SECONDS` | `300` | ECS task definition or `.env` | How often world saves are synced to S3 (seconds) |
| `BACKUP_INTERVAL_SECONDS` | `3600` | ECS task definition or `.env` | How often a timestamped zip backup is uploaded to `s3://$S3_BUCKET/$WORLD/backups/` (seconds); backups expire after 30 days via S3 lifecycle |

### Idle shutdown

Controlled by `watchdog.sh`. The watchdog samples UDP datagrams every 10 seconds; if the count stays below `IDLE_DATAGRAM_MAX_COUNT` for `IDLE_THRESHOLD_MINUTES` consecutive minutes, it stops the server, syncs saves, and shuts down the container.

| Name | Default | Defined in | Purpose |
| --- | --- | --- | --- |
| `IDLE_THRESHOLD_MINUTES` | `10` | ECS task definition (Terraform hardcodes `"10"`) | Consecutive idle minutes before self-termination |
| `IDLE_DATAGRAM_WINDOW` | `3` | ECS task definition or `.env` | Seconds to collect UDP datagrams during each activity check |
| `IDLE_DATAGRAM_MAX_COUNT` | `30` | ECS task definition or `.env` | Datagram count at or below which the server is considered idle |

### Cloudflare DNS

All three vars must be set for DNS registration to run. If any is absent, `cloudflare.sh` exits silently. On ECS, `CF_API_TOKEN` is injected from AWS Secrets Manager; the others are set in the task definition via Terraform variables.

| Name | Default | Defined in | Purpose |
| --- | --- | --- | --- |
| `CF_API_TOKEN` | — | AWS Secrets Manager (`valheim-server-cf-api-token`) | Cloudflare API token with DNS edit permission for the zone |
| `CF_ZONE_ID` | — | ECS task definition (`var.cf_zone_id` in Terraform) | Cloudflare zone ID |
| `CF_DOMAIN` | — | ECS task definition (`var.cf_domain` in Terraform) | Base domain; the per-world A record is `$WORLD.$CF_DOMAIN` |

### Container internals (baked into the image)

Set as `ENV` in `docker/ecs/Dockerfile`. Do not override these — the scripts depend on fixed paths.

| Name | Value | Purpose |
| --- | --- | --- |
| `USER` | `steam` | Container user that runs the server |
| `HOMEDIR` | `/home/steam` | Home directory |
| `STEAMCMDDIR` | `/usr/games/steamcmd` | SteamCMD install path |
| `STEAMAPPID` | `896660` | Steam app ID for Valheim Dedicated Server (used by SteamCMD) |
| `STEAMAPP` | `valheim` | Steam app name |
| `STEAMAPPDIR` | `/home/steam/valheim-dedicated` | Valheim server install directory |

### Set at runtime by scripts (not user-configurable)

| Name | Set by | Value |
| --- | --- | --- |
| `SteamAppId` | `start_server.sh` | `892970` — Valheim client app ID required by the server binary |
| `LD_LIBRARY_PATH` | `start_server.sh` | Prepended with `./linux64` before exec'ing the server binary |

---

## `server.env` format

A plain `KEY=VALUE` file uploaded to `s3://$S3_BUCKET/$WORLD/server.env`. It is sourced with `set -a` so every key becomes an exported variable. Example:

```sh
SERVER_NAME=My Valheim World
SERVER_WORLD=myworld
SERVER_PASSWORD=hunter2
SERVER_PORT=2456
SERVER_PUBLIC=0
```

See `docker/ecs/test/*/server.env` for working examples used in local development.
