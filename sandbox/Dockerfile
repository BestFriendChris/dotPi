FROM docker/sandbox-templates:shell

USER root

# System packages
RUN apt-get update && apt-get install -y \
    tmux \
    curl \
    fd-find \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s $(which fdfind) /usr/local/bin/fd

# just — detect arch for correct binary
ARG JUST_VERSION=1.46.0
RUN ARCH=$(uname -m) && \
    curl -fsSL "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-${ARCH}-unknown-linux-musl.tar.gz" \
    | tar xz -C /usr/local/bin just

# jj — detect arch for correct binary
ARG JJ_VERSION=0.39.0
RUN ARCH=$(uname -m) && \
    curl -fsSL "https://github.com/jj-vcs/jj/releases/download/v${JJ_VERSION}/jj-v${JJ_VERSION}-${ARCH}-unknown-linux-musl.tar.gz" \
    | tar xz -C /usr/local/bin

# pi (installed globally via npm)
RUN npm install -g @mariozechner/pi-coding-agent

# sync-settings script
COPY sync-settings.sh /usr/local/bin/sync-settings
RUN chmod +x /usr/local/bin/sync-settings

# tmux config
COPY tmux.conf /etc/tmux.conf

USER agent

# bashrc additions
COPY bashrc.sh /tmp/bashrc-extra.sh
RUN mkdir -p ~/bin && cat /tmp/bashrc-extra.sh >> ~/.bashrc
