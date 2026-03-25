# dotPi

BestFriendChris's experiments with [pi](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent) — an AI coding agent.

## Prerequisites

This repo assumes you have [BestFriendChris/dotfiles](https://github.com/BestFriendChris/dotfiles) set up, which provides the `~/.config` settings that get mounted into the sandbox. Eventually this repo may be folded into that one once things stabilize.

## What's in here?

### Sandbox (`sandbox/` + `bin/pie`)

A turnkey way to run `pi` inside an isolated Docker sandbox (via Docker Desktop's sandbox feature). When you launch the sandbox, it automatically:

1. Mounts your project directory and select config paths (`~/.pi`, `~/.config`)
2. Syncs dotfiles from your macOS home into the sandbox
3. Drops you into a **tmux** session with `pi` running

The sandbox comes pre-loaded with useful tools: `just`, `jj`, `fd`, `tmux`, `curl`, and `pi` itself.

#### Quick Start

From any project directory:

```bash
pie sandbox
```

This single command will **build** the Docker image (if needed), **create** a sandbox (if needed), and **run** it. The sandbox name is derived from the project's git/jj root (e.g., `pi-myproject`).

If the Dockerfile or any of its copied files have changed since the last build, the image is automatically rebuilt and the sandbox recreated.

#### Commands

| Command | Description |
|---|---|
| `pie sandbox` | Smart launch — build, create, and run as needed |
| `pie sandbox-info` | Show the resolved sandbox name and project root |
| `pie sandbox-build` | Build (or rebuild) the Docker image |
| `pie sandbox-create` | Create a new sandbox, removing any existing one |
| `pie sandbox-destroy` | Stop and remove the sandbox |
| `pie sandbox-run` | Run an already-created sandbox |
| `pie help` | Show help |

Extra mounts can be passed when creating a sandbox:

```bash
pie sandbox-create -m ~/other-config -m ~/data
```

#### How It Works

1. **`pie sandbox`** checks if the Docker image (`dotpi-sandbox:latest`) exists and is up-to-date with the Dockerfile. If not, it rebuilds.
2. It then checks if a sandbox named `pi-<project>` exists. If not (or if the image changed), it creates one, mounting the project root plus `~/.pi` and `~/.config`.
3. On first login inside the sandbox, `sync-settings.sh` runs automatically — it symlinks dotfiles from the mounted macOS home (`/Users/<you>/`) into the sandbox agent's home, giving you your familiar shell config, git settings, etc.
4. Interactive sessions auto-launch **tmux** with **pi** running inside, so you're immediately ready to work.

## Project Structure

```
bin/
  pie                # CLI entrypoint — manages the sandbox lifecycle
sandbox/
  Dockerfile         # Sandbox image (based on docker/sandbox-templates:shell)
  bashrc.sh          # Settings sync on first login, tmux+pi auto-launch
  sync-settings.sh   # Symlinks dotfiles from mounted macOS home into sandbox
  tmux.conf          # tmux config (extended keys, 256color)
```
