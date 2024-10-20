#/bin/bash
sudo mkdir /opt/data
sudo chown 1000:1000 /opt/data
sudo chmod 777 /opt/data
docker network create --subnet 172.20.0.0/16 mynetwork
docker compose up --profile no-vpn up