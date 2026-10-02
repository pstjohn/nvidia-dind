# syntax=docker/dockerfile:1
FROM docker.io/nvidia/cuda:13.1.1-runtime-ubuntu24.04

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
        apt-utils \
        ca-certificates \
        openssh-client \
        curl \
        iptables \
        gnupg \
        build-essential \
        git \
        gh \
        htop \
        jq \
        less \
        procps \
        python3 \
        python3-venv \
        ripgrep \
        rsync \
        sudo \
        tini \
        tmux \
        unzip \
        util-linux \
        vim \
        xz-utils

# Node LTS includes npm; distro Node is too old for the coding agents.
ARG NODE_VERSION=24.21.0
RUN set -eu; \
    case "$(dpkg --print-architecture)" in \
        amd64) node_arch=x64 ;; arm64) node_arch=arm64 ;; *) exit 1 ;; \
    esac; \
    archive="node-v${NODE_VERSION}-linux-${node_arch}.tar.xz"; \
    work="$(mktemp -d)"; \
    cd "$work"; \
    curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/${archive}"; \
    curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt"; \
    grep " ${archive}$" SHASUMS256.txt | sha256sum --check --strict; \
    tar -xJf "$archive" --strip-components=1 -C /usr/local; \
    cd /; rm -rf "$work"; \
    node --version; npm --version

ARG PI_VERSION=1.0.0
ARG PASEO_VERSION=0.10.3
RUN npm install --global \
        --allow-scripts=esbuild,node-pty,@google/genai,protobufjs \
        "@earendil-works/pi-coding-agent@${PI_VERSION}" \
        "@getpaseo/cli@${PASEO_VERSION}" && \
    npm cache clean --force

# Keep Python CLIs isolated from Ubuntu's externally managed Python.
# AWS CLI v1 matches existing provisioning and includes `aws s3` / PBSS support.
ARG AWSCLI_VERSION=1.46.1
ARG LEPTONAI_VERSION=0.27.3
RUN python3 -m venv /opt/awscli && \
    /opt/awscli/bin/pip install --no-cache-dir "awscli==${AWSCLI_VERSION}" && \
    ln -s /opt/awscli/bin/aws /usr/local/bin/aws && \
    python3 -m venv /opt/leptonai && \
    /opt/leptonai/bin/pip install --no-cache-dir "leptonai==${LEPTONAI_VERSION}" && \
    ln -s /opt/leptonai/bin/lep /usr/local/bin/lep

# NVIDIA Container Toolkit & Docker
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID) && \
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && \
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
        | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
        | tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
    apt-get update && \
    apt-get install -y nvidia-container-toolkit docker.io

# missing dockremap user

ENV DOCKER_TLS_CERTDIR=/certs
RUN mkdir /certs /certs/client && chmod 1777 /certs /certs/client

# https://github.com/docker-library/docker
ADD https://raw.githubusercontent.com/docker-library/docker/master/modprobe.sh /usr/local/bin/modprobe
ADD https://raw.githubusercontent.com/docker-library/docker/master/dockerd-entrypoint.sh /usr/local/bin/
ADD https://raw.githubusercontent.com/docker-library/docker/master/docker-entrypoint.sh /usr/local/bin/
ADD https://raw.githubusercontent.com/moby/moby/master/hack/dind /usr/local/bin/dind

RUN chmod +x /usr/local/bin/dockerd-entrypoint.sh /usr/local/bin/docker-entrypoint.sh /usr/local/bin/dind

# AWS CLI v1's built-in help renderer requires groff.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y groff

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["dockerd-entrypoint.sh"]
CMD []
