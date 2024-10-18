#! /bin/bash
sudo docker compose --profile vpn stop && \
sudo docker compose --profile vpn up -d