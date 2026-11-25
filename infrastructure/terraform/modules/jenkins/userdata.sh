#!/bin/bash

set -Eeuo pipefail

exec > >(tee -a /var/log/cloudmusic-bootstrap.log) 2>&1

trap 'echo "Bootstrap failed at line $LINENO"' ERR

export DEBIAN_FRONTEND=noninteractive

echo "Starting CloudMusic Jenkins installation"

# 1. Install dependencies
apt-get update

apt-get install -y \
  openjdk-21-jdk \
  git \
  curl \
  wget \
  unzip \
  jq \
  ca-certificates \
  gnupg \
  gitleaks

mkdir -p /etc/apt/keyrings

# 2. Install Jenkins LTS
curl -fsSL --retry 5 \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
  -o /etc/apt/keyrings/jenkins-keyring.asc

chmod 644 /etc/apt/keyrings/jenkins-keyring.asc

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list

apt-get update
apt-get install -y jenkins

# 3. Install Docker Engine
curl -fsSL --retry 5 \
  https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc

chmod 644 /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update

apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

systemctl enable --now docker

usermod -aG docker jenkins

# 4. Install AWS CLI v2
if ! command -v aws >/dev/null 2>&1; then
  cd /tmp

  curl -fsSL --retry 5 \
    https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
    -o awscliv2.zip

  unzip -q awscliv2.zip
  ./aws/install

  rm -rf /tmp/aws /tmp/awscliv2.zip
fi

# 5. Install Trivy
curl -fsSL --retry 5 \
  https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | gpg --dearmor --yes \
    -o /etc/apt/keyrings/trivy.gpg

chmod 644 /etc/apt/keyrings/trivy.gpg

echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
  > /etc/apt/sources.list.d/trivy.list

apt-get update
apt-get install -y trivy

# 6. Configure SSM Agent
if ! snap list amazon-ssm-agent >/dev/null 2>&1; then
  snap install amazon-ssm-agent --classic
fi

snap start --enable amazon-ssm-agent

# 7. Start Jenkins
systemctl daemon-reload
systemctl enable jenkins
systemctl restart jenkins

# 8. Verify installations
java -version
jenkins --version
docker --version
docker buildx version
aws --version
git --version
trivy --version
gitleaks version

systemctl is-active docker
systemctl is-active jenkins

# 9. Verify Jenkins Docker access
runuser -u jenkins -- docker info >/dev/null

# 10. Create bootstrap completion marker
touch /var/log/cloudmusic-bootstrap-success

echo "CloudMusic Jenkins installation completed successfully"

