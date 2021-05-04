FROM debian:10

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Utility versions

# The version of Node JS to install
ARG NODE_VERSION=12.x

# The version of Go Lang install found at https://golang.org/dl/
ARG GO_VERSION=1.16.3

# Docker Compose version may be found at https://github.com/docker/compose/releases
ARG COMPOSE_VERSION=1.29.1

# Latest version of Terraform may be found at https://www.terraform.io/downloads.html
ARG TERRAFORM_VERSION=0.15.1

# Latest version of Terrform Linter may be found at https://github.com/terraform-linters/tflint/releases
ARG TFLINT_VERSION=0.28.0

# Latest version of helm may be found at https://github.com/helm/helm/releases
ARG HELM_VERSION=3.5.4

# Latest version of dotnet core SDK
ARG DOTNET_VERSION=5.0

# Azure Functions CLI may be found at https://github.com/Azure/azure-functions-core-tools/releases
ARG AZFUNC_CLI_VERSION=3.0.3442

# Linkerd may be found at https://github.com/linkerd/linkerd2/releases
ARG LINKERD_CLI_VERSION=stable-2.9.5

# This Dockerfile adds a non-root user with sudo access. Use the "remoteUser"
# property in devcontainer.json to use it. On Linux, the container user's GID/UIDs
# will be updated to match your local UID/GID (when using the dockerFile property).
# See https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create a temp directory for downloads
RUN mkdir -p /tmp/downloads

# Configure apt and install generic packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-utils dialog 2>&1 \
    #
    # Verify git, process tools installed
    && apt-get install -y \
        git \
        openssh-client \
        iproute2 \
        curl \
        procps \
        unzip \
        apt-transport-https \
        ca-certificates \
        gnupg-agent \
        software-properties-common \
        gnupg2 \
        python3-pip \
        squashfs-tools \
        lsb-release 2>&1

# Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support for the non-root user
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install Go
RUN curl -sSL -o /tmp/downloads/golang.tar.gz https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz  \
    && tar -C /usr/local -xzf /tmp/downloads/golang.tar.gz

ENV PATH=$PATH:/usr/local/go/bin

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

# Install some NPM packages
RUN npm install -g \
    @vue/cli \
    @angular/cli

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
    && helm repo add stable https://charts.helm.sh/stable/

# Install .NET Core 3.1
ENV \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip

RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-buster-prod buster main" > /etc/apt/sources.list.d/microsoft.list \ 
    && apt-get update \
    && apt-get install -y dotnet-sdk-${DOTNET_VERSION}

# Install Dapr CLI
RUN curl -sL https://raw.githubusercontent.com/dapr/cli/master/install/install.sh | /bin/bash

# Install Azure Functions Core Tools v3
RUN curl -s -L https://github.com/Azure/azure-functions-core-tools/releases/download/${AZFUNC_CLI_VERSION}/Azure.Functions.Cli.linux-x64.${AZFUNC_CLI_VERSION}.zip -o /tmp/downloads/azfunc.zip \
    && mkdir -p /tmp/downloads/azfunc \
    && unzip -qq -d /tmp/downloads/azfunc /tmp/downloads/azfunc.zip \
    && mv /tmp/downloads/azfunc /usr/local/bin/azfunc \
    && cd /usr/local/bin/azfunc \
    && chmod +x func \
    && ln -s /usr/local/bin/azfunc/func /usr/bin/func

# Install FluxCD 2.x
run curl -s https://fluxcd.io/install.sh | sudo bash

# Install Kustomize
run cd /usr/local/bin \
    && curl -s https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh | bash

# Install Linkerd
RUN curl -s -L https://github.com/linkerd/linkerd2/releases/download/${LINKERD_CLI_VERSION}/linkerd2-cli-${LINKERD_CLI_VERSION}-linux -o /usr/local/bin/linkerd \
    && chmod +x /usr/local/bin/linkerd

# Install GoLang and Powerline for the bash shell
RUN go get -u github.com/justjanne/powerline-go

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/downloads

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog