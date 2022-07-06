# Create docker network

docker create network radarr

# Install radarr

docker run -d   --name=radarr   -e PUID=1000   -e PGID=1000   -e TZ=Europe/London   -p 7878:7878 -v radarr-data:/config --restart unless-stopped -v $HOME/movies:/downloads --net radarr  lscr.io/linuxserver/radarr:latest

# Install Transmission

Download directory must be same for Radarr and Transmission

docker run -d   --name=transmission   -e PUID=1000   -e PGID=1000   -e TZ=Europe/London -p 9091:9091   -p 51413:51413   -p 51413:51413/udp   -v transmission-config:/config  -v $HOME/movies:/downloads -v transmission-watch:/watch --restart unless-stopped --net radarr  lscr.io/linuxserver/transmission:latest

# Install Jackett

docker run -d   --name=jackett   -e PUID=1000   -e PGID=1000   -e TZ=Europe/London -p 9117:9117 -v jackett-config:/config -v jackett-downloads:/downloads --restart unless-stopped --net radarr  lscr.io/linuxserver/jackett:latest

# Install Jellyfin (Optional)

Download directory same as Transmissiona and Radarr

docker run -d   --name=jellyfin   -e PUID=1000   -e PGID=1000   -e TZ=Europe/London -p 8096:8096 -p 7359:7359/udp -v jellyfin-config:/config -v transmission-download:/data/movies --restart unless-stopped --net radarr  lscr.io/linuxserver/jellyfin:latest

# Add indexer to Jackett

- Open Jackett UI at http://localhost:9117
- Add indexer
- Search for torrent indexer (e.g. the pirates bay)
- Add selected

# Configure Radarr

- Open Radarr at http://localhost:7878
- Settings --> Media Management --> Check mark "Movies deleted from disk are automatically unmonitored in Radarr" under File management section --> Save
- Settings --> Indexers --> Add --> Add Rarbg indexer --> Add minimum seeder (4) --> Test --> Save
- Settings --> Indexers --> Add --> Torznab --> Follow steps from Jackett to add indexer
- Settings --> Download clients --> Transmission --> Add Host (transmission) and port (9091) --> Username and password if added --> Test --> Save

# Add a movie

- Movies --> Search for a movie --> Add Root folder (/downloads) --> Quality profile --> Add movie
- Go to transmission (http://localhost:9091) and see if movie is getting downloaded.

# Configure Jellyfin

- Open Jellyfin at http://localhost:8096
- Configure as it asks for first time.
- Add media library folder and choose /data/movies/

# Configure Nginx

- Get inside Nginx container
- `cd /etc/nginx/conf.d`
- Add proxies as per below for all tools.
- Close ports of other tools in firewall/security groups except port 80 and 443.


# Radarr Nginx reverse proxy

- Settings --> General --> URL Base --> Add base (/radarr)
- Add below proxy in nginx configuration

```
location /radarr {
    proxy_pass http://radarr:7878;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
```

# Jackett Nginx reverse proxy

To be added