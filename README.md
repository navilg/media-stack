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
- Settings --> General --> Enable advance setting --> Select AUthentication and add username and password

# Add a movie

- Movies --> Search for a movie --> Add Root folder (/downloads) --> Quality profile --> Add movie
- Go to transmission (http://localhost:9091) and see if movie is getting downloaded.

# Configure Jellyfin

- Open Jellyfin at http://localhost:8096
- Configure as it asks for first time.
- Add media library folder and choose /data/movies/

# Configure Jackett

- Add admin password

# Apply SSL in Nginx

- Open port 80 and 443.
- Get inside Nginx container and install certbot and certbot-nginx `apk add certbot certbot-nginx`
- Add URL in server block. e.g. `server_name  localhost armdev.navratangupta.in;` in /etc/nginx/conf.d/default.conf
- Run `certbot --nginx` and provide details asked.


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
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
  }
```

- Restart containers.

# Jackett Nginx reverse proxy

- Get inside jackett container and go to `/config/Jackett/`
- Add `"BasePathOverride": "/jackett"` in ServerConfig.json file.
- Add below proxy

```
location /jackett/ {
    proxy_pass         http://jackett:9117;
    proxy_http_version 1.1;
    proxy_set_header   Upgrade $http_upgrade;
    proxy_set_header   Connection keep-alive;
    proxy_cache_bypass $http_upgrade;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   X-Forwarded-Host $http_host;
}
```

- Restart containers

# Transmission Nginx reverse proxy

- Add below proxy in Nginx config

```
location ^~ /transmission {
      
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header Host $http_host;
          proxy_set_header X-NginX-Proxy true;
          proxy_http_version 1.1;
          proxy_set_header Connection "";
          proxy_pass_header X-Transmission-Session-Id;
          add_header   Front-End-Https   on;
      
          location /transmission/rpc {
              proxy_pass http://transmission:9091;
          }
      
          location /transmission/web/ {
              proxy_pass http://transmission:9091;
          }
      
          location /transmission/upload {
              proxy_pass http://transmission:9091;
          }
          
          location /transmission {
              return 301 https://$host/transmission/web;
          }
}
```

# Jellyfin Nginx proxy

- Add base URL, Admin Dashboard -> Networking -> Base URL (/jellyfin)
- Add below config in Ngix config

```
 location /jellyfin {
        return 302 $scheme://$host/jellyfin/;
    }

    location /jellyfin/ {

        proxy_pass http://jellyfin:8096/jellyfin/;

        proxy_pass_request_headers on;

        proxy_set_header Host $host;

        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $http_host;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $http_connection;

        # Disable buffering when the nginx proxy gets very resource heavy upon streaming
        proxy_buffering off;
    }
```
- Restart containers