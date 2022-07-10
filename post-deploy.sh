#!/usr/bin/env bash

docker exec -it transmission mkdir /downloads/movies
docker exec -it transmission mkdir chown 1000:1000 /downloads/movies

docker exec -it transmission mkdir /downloads/tvshows
docker exec -it transmission mkdir chown 1000:1000 /downloads/tvshows