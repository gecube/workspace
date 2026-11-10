# syntax=docker/dockerfile:1
# Workspace image: the developer's long-lived pod. tmux, Claude Code and Codex
# run here; ContainerSSH execs every session into it.
#
# Every tool is pinned. Claude Code does not self-update (the binary sits in
# /usr/local/bin, which the developer cannot write); bump CLAUDE_CODE_VERSION
# here instead. Build and push: build.sh (ghcr.io/gecube/workspace).
FROM docker.io/containerssh/agent:v0.11.0@sha256:5917ca67551684f9f3da886c0a1fee79127fa3d8f671ceb50367c17a44afe2d3 AS agent

FROM docker.io/library/debian:trixie-20261104-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

ARG GO_VERSION=1.27.3
ARG GO_SHA256=65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40
ARG CODEX_VERSION=rust-v0.167.0
ARG CODEX_SHA256=9d64836106d5b374e90ee4454c7ebcde7ca7106558bd7e41a34b9f26ebda251a
ARG CLAUDE_CODE_VERSION=2.1.311
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash-completion build-essential ca-certificates curl dnsutils git iproute2 jq less \
      nodejs npm openssh-client openssh-sftp-server procps python3 python3-venv ripgrep rsync \
      tini tmux unzip vim-tiny wget xz-utils zsh \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSLo /tmp/go.tgz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
 && echo "${GO_SHA256}  /tmp/go.tgz" | sha256sum -c - \
 && tar -C /usr/local -xzf /tmp/go.tgz \
 && rm /tmp/go.tgz

RUN curl -fsSLo /tmp/codex.tgz "https://github.com/openai/codex/releases/download/${CODEX_VERSION}/codex-x86_64-unknown-linux-musl.tar.gz" \
 && echo "${CODEX_SHA256}  /tmp/codex.tgz" | sha256sum -c - \
 && tar -xzf /tmp/codex.tgz -C /tmp \
 && install -m 0755 /tmp/codex-x86_64-unknown-linux-musl /usr/local/bin/codex \
 && rm -f /tmp/codex*

# The installer verifies the binary against its release manifest. It puts the
# binary under ~/.local, which /home/dev (the PVC) would hide, so move it.
RUN curl -fsSL https://claude.ai/install.sh | bash -s "${CLAUDE_CODE_VERSION}" \
 && install -m 0755 "$(readlink -f /root/.local/bin/claude)" /usr/local/bin/claude \
 && rm -rf /root/.local /root/.claude /root/.claude.json /root/.cache

COPY --from=agent /usr/bin/containerssh-agent /usr/bin/containerssh-agent

RUN useradd --create-home --uid 1000 --shell /bin/bash dev
COPY --chmod=0755 ws-init.sh /usr/local/bin/ws-init
COPY --chmod=0644 ws-profile.sh /etc/profile.d/ws.sh
COPY --chmod=0644 tmux.conf /etc/tmux.conf

ENV PATH=/home/dev/.local/bin:/home/dev/go/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    DISABLE_AUTOUPDATER=1
USER 1000
WORKDIR /home/dev
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/ws-init"]
