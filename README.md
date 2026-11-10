# workspace

The image behind our developer workspaces: a long-lived pod per developer
that [ContainerSSH](https://containerssh.io) execs every SSH session
into. Published as `ghcr.io/gecube/workspace`.

## What is inside

- Debian 13 slim, pinned by digest
- Claude Code and Codex, pinned; neither updates itself
- Go, Node, Python 3 with venv, build-essential
- tmux, zsh, git, curl, jq, ripgrep, rsync, vim-tiny
- the ContainerSSH guest agent and `sftp-server`

Versions are the `ARG`s and `FROM` lines at the top of the `Dockerfile`;
downloads are checked against their sha256.

## How it behaves

- Runs as `dev` (uid 1000) with no root: the pods run under the Kubernetes
  `restricted` Pod Security profile, so everything a developer needs has to be
  in the image or in the home directory.
- `/home/dev` is the developer's volume. On the first start `ws-init` copies
  `/etc/skel` into it, then keeps the container alive.
- An interactive login lands in the tmux session `main`, so what runs there
  survives a disconnect. `ssh -o SetEnv=WS_NO_TMUX=1 ...` opts out.

## Build and publish

```sh
./build.sh            # build the committed tree, push, print tag and digest
./build.sh --no-push  # build only
```

The tag is `<UTC time>-<commit>`, so commit before building. The push logs in
with the `gh` CLI token (scope `write:packages`) through a throwaway
`DOCKER_CONFIG`. What runs is decided elsewhere: the tag and digest are pinned
in the cluster's GitOps tree.
