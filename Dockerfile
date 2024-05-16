FROM registry.access.redhat.com/ubi9:9.3-1552@sha256:1fafb0905264413501df60d90a92ca32df8a2011cbfb4876ddff5ceb20c8f165
LABEL description="Renovate Openshift Pipeline" \
      summary="Renovate Openshift Pipeline basic container image" \
      maintainer="EXD Rebuilds Guild <exd-guild-rebuilds@redhat.com >"

# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=37.303.2

# Using OpenSSL store allows for external modifications of the store. It is needed for the internal Red Hat cert.
ENV NODE_OPTIONS=--use-openssl-ca

RUN curl -Lo /etc/yum.repos.d/rhel7-csb-stage.repo http://hdn.corp.redhat.com/rhel7-csb-stage/rhel7-csb-stage.repo && \
    sed -i 's/https:/http:/;s/gpgcheck=1/gpgcheck=0/' /etc/yum.repos.d/rhel7-csb-stage.repo && \
    dnf update -y && \
    dnf install -y redhat-internal-cert-install git python3-dnf python3-pip podman && \
    dnf module install -y nodejs:18/common && \
    dnf clean all && \
    rpm --install --verbose \
        https://github.com/tektoncd/cli/releases/download/v0.35.1/tektoncd-cli-0.35.1_Linux-64bit.rpm

RUN npm install -g pnpm@^8.15.7

WORKDIR /app/renovate

COPY . .

# Install project dependencies
RUN pnpm install

# Build Renovate
RUN pnpm build

# Install executables into a global dir
RUN npm install -g .

WORKDIR /app/rpm-lockfile-prototype

# Clone and install the rpm-lockfile-prototype
# We must pass --no-dependencies, otherwise it would try to
# fetch dnf from PyPI, which is just a dummy package
RUN git clone https://github.com/konflux-ci/rpm-lockfile-prototype.git .
RUN pip3 install jsonschema PyYaml productmd requests
RUN pip3 install --no-dependencies .

WORKDIR /workspace
