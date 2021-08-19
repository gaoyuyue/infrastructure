#!/bin/bash
set -euo pipefail

#install wget
sudo apt-get update
sudo apt-get install wget

# install docker
sudo apt install -yqq apt-transport-https ca-certificates curl gnupg2 software-properties-common && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
sudo apt-get update && \
sudo apt-get install -yqq docker-ce && \
sudo usermod -aG docker ${USER}
echo "✅ docker installed"

# install kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

sudo apt-get install -yqq kubectl git
echo "✅ kubectl installed"

# install azure pipeline agent
mkdir myagent && cd myagent
wget https://vstsagentpackage.azureedge.net/agent/2.190.0/vsts-agent-linux-x64-2.190.0.tar.gz
tar zxvf vsts-agent-linux-x64-2.190.0.tar.gz
./config.sh --unattended \
  --agent "${AZP_AGENT_NAME:-$(hostname)}" \
  --url "$AZP_URL" \
  --auth PAT \
  --token "$AZP_TOKEN" \
  --pool "${AZP_POOL:-Default}" \
  --work "${AZP_WORK:-_work}" \
  --replace \
  --acceptTeeEula & wait $!
sudo ./svc.sh install
sudo ./svc.sh start
echo "✅ azure pipeline agent installed"