#/bin/bash

docker network create --subnet 172.20.0.0/16 mynetwork
docker compose up --profile no-vpn up