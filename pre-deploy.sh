#!/usr/bin/env bash

docker network ls | grep -i mynetwork || docker network create mynetwork    # Create network if not already exist