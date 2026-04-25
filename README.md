# dev-server

Ansible-based provisioning for a remote development server on Hetzner Cloud (Singapore, cpx62).

## Workflow

```
provision.sh             # Start (fresh or from snapshot)
  → develop
snapshot-and-destroy.sh  # Save + stop (end of day)
  → provision.sh         # Resume next time
```

## Setup

1. Copy `.env.example` to `.env` and fill in your Hetzner API token:
   ```sh
   cp .env.example .env
   # edit .env and set HCLOUD_TOKEN
   ```

2. Ensure `hcloud` CLI is installed and authenticated:
   ```sh
   hcloud context list
   ```

3. Ensure Ansible is installed locally:
   ```sh
   ansible --version
   ```

## Scripts

| Script | Description |
|--------|-------------|
| `scripts/provision.sh` | Create server. Restores from snapshot if one exists, otherwise creates fresh and runs full bootstrap (~8 min). |
| `scripts/snapshot-and-destroy.sh` | Snapshot the running server then delete it. Keeps `SNAPSHOTS_TO_KEEP` most recent snapshots. |
| `scripts/restore.sh` | Create server from latest snapshot (called by provision.sh automatically). |
| `scripts/destroy.sh` | Delete server without snapshotting (prompts for confirmation). |
| `scripts/bootstrap.sh` | Run Ansible playbook against inventory/hosts.ini (called by provision.sh on fresh installs). |

## SSH config

After `provision.sh` completes it prints an SSH config snippet. Add it to `~/.ssh/config`:

```
Host hetzner-dev
    HostName <printed IP>
    User sinder
    IdentityFile ~/.ssh/id_ed25519
```

After a restore, update the `HostName` to the new IP printed by `restore.sh`.

```sh
bash scripts/bootstrap.sh
```
