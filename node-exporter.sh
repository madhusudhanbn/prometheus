#!/bin/bash

echo Removing old version of Node exporter
systemctl stop node_exporter
sudo rm -rf $(which node_exporter)

echo Dowinloading and installing latest version of Node exporter

NODE_EXPORTER_VERSION=$(repo="prometheus/node_exporter" && curl --silent "https://api.github.com/repos/$repo/releases/latest" | grep -Po '"tag_name": "v\K.*?(?=")')
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz -O /tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xzvf /tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cd /tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64
cp node_exporter /usr/local/bin

# create user
useradd --no-create-home --shell /bin/false node_exporter

chown node_exporter:node_exporter /usr/local/bin/node_exporter

echo '[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/node_exporter.service

# enable node_exporter in systemctl
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter


echo "Setup complete.
Add the following lines to /etc/prometheus/prometheus.yml:

  - job_name: 'node_exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9100']
"

echo Cleaning up left over files
sudo rm -rf /tmp/node_exporter*
