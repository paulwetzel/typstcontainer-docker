# syntax=docker/dockerfile:1.7

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
ARG TYPST_VERSION=0.14.2

LABEL org.opencontainers.image.title="Typst Dev Container Base"
LABEL org.opencontainers.image.description="Base image for VS Code dev containers with Typst preinstalled"
LABEL org.opencontainers.image.source="https://github.com/paulwetzel/typstcontainer-docker"
LABEL org.opencontainers.image.licenses="GPL-3.0"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Base packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    fontconfig \
    fonts-dejavu \
    fonts-liberation \
    fonts-noto \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    git \
    git-lfs \
    jq \
    make \
    openssh-client \
    sudo \
    unzip \
    wget \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for devcontainers
RUN EXISTING_GROUP="$(getent group "${USER_GID}" | cut -d: -f1 || true)" \
    && if [ -z "${EXISTING_GROUP}" ]; then \
         groupadd --gid "${USER_GID}" "${USERNAME}"; \
       fi \
    && if ! id -u "${USERNAME}" >/dev/null 2>&1; then \
         useradd --uid "${USER_UID}" --gid "${USER_GID}" -m "${USERNAME}" -s /bin/bash; \
       fi \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Install Typst
RUN ARCH="$(dpkg --print-architecture)" \
    && case "${ARCH}" in \
         amd64) TYPST_ARCH="x86_64-unknown-linux-musl" ;; \
         arm64) TYPST_ARCH="aarch64-unknown-linux-musl" ;; \
         *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
       esac \
    && curl -fsSL -o /tmp/typst.tar.xz \
       "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-${TYPST_ARCH}.tar.xz" \
    && mkdir -p /tmp/typst \
    && tar -xJf /tmp/typst.tar.xz -C /tmp/typst --strip-components=1 \
    && install -m 0755 /tmp/typst/typst /usr/local/bin/typst \
    && rm -rf /tmp/typst /tmp/typst.tar.xz \
    && typst --version

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

USER ${USERNAME}
WORKDIR /workspaces

CMD ["/bin/bash"]