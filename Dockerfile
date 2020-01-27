FROM debian:10

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Utility versions

# The version of Node JS to install
ARG NODE_VERSION=12.x

# Docker Compose version
ARG COMPOSE_VERSION=1.24.0

# Latest version of Terraform may be found at https://www.terraform.io/downloads.html
ARG TERRAFORM_VERSION=0.12.18

# Latest version of Terrform Linter may be found at https://github.com/terraform-linters/tflint/releases
ARG TFLINT_VERSION=0.13.4

# Latest version of helm may be found at https://github.com/helm/helm/releases
ARG HELM_VERSION=3.0.2

# Create a temp directory for downloads
RUN mkdir -p /tmp/downloads

# Configure apt and install generic packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-utils dialog 2>&1 \
    #
    # Verify git, process tools installed
    && apt-get install -y \
        git \
        iproute2 \
        curl \
        procps \
        unzip \
        apt-transport-https \
        ca-certificates \
        gnupg-agent \
        software-properties-common \
        gnupg2 \
        lsb-release 2>&1

# Install Docker CE CLI
RUN apt-get update \
    && curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | apt-key add - 2>/dev/null \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install -y docker-ce-cli

# Install Docker Compose
RUN curl -sSL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Node JS
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - \
    && apt-get update \
    && apt-get install -y nodejs

# Install the Azure CLI
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list \
    && curl -sL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - 2>/dev/null \
    && apt-get update \
    && apt-get install -y azure-cli

# Install Terraform, tflint, and graphviz
RUN curl -sSL -o /tmp/downloads/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip /tmp/downloads/terraform.zip \
    && mv terraform /usr/local/bin \
    && curl -sSL -o /tmp/downloads/tflint.zip https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip \
    && unzip /tmp/downloads/tflint.zip \
    && mv tflint /usr/local/bin \
    && cd ~ \ 
    && apt-get install -y graphviz

# Install Kubectl
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list \ 
    && curl -sL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - 2>/dev/null \
    && apt-get update \
    && apt-get install -y kubectl

# Install Helm
RUN curl -sSL -o /tmp/downloads/helm.tar.gz https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    && mkdir -p /tmp/downloads/helm \
    && tar -C /tmp/downloads/helm -zxvf /tmp/downloads/helm.tar.gz \
    && mv /tmp/downloads/helm/linux-amd64/helm /usr/local/bin \
    && helm repo add stable https://kubernetes-charts.storage.googleapis.com/

# Install Dapr CLI
RUN curl -sL https://raw.githubusercontent.com/dapr/cli/master/install/install.sh | /bin/bash

# Install GoLang and Powerline for the bash shell
RUN apt install -y golang-go \
    && go get -u github.com/justjanne/powerline-go

# Copy in the bash settings file
COPY .bashrc /root/.bashrc

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/downloads

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog