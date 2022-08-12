# Install media stack

There are two media stacks available.

`stack-1` This stack contains Jellyfin, Radarr, Sonarr, Jackett and Transmission.

`stack-2` This stack contains Jellyfin, Radarr, Sonarr, Prowlarr, qBitTorrent and VPN.

Any one of them can be deployed using --profile option with docker-compose.

```
docker network create mynetwork

# Install Jellyfin, Radarr, Sonarr, Jackett and Transmission stack
docker-compose --profile stack-1 up -d

# Or, Install Jellyfin, Radarr, Sonarr, Prowlarr, qBitTorrent and VPN stack
## By default NordVPN is configured. This can be changed to ExpressVPN, SurfShark, OpenVPN or Wireguard VPN by updating docker-compose.yml file. It uses OpenVPN type for all providers.

VPN_SERVICE_PROVIDER=nordvpn OPENVPN_USER=openvpn-username OPENVPN_PASSWORD=openvpn-password SERVER_REGIONS=Switzerland docker-compose --profile stack-2 up -d

docker-compose -f docker-compose-nginx.yml up -d # OPTIONAL to use Nginx as reverse proxy
```

# Configure Transmission / qBittorrent

For qBitTorrent, 

- Open qBitTorrent at http://localhost:5080. Default username:password is admin:adminadmin
- Go to Tools --> Options --> WebUI --> Change password

For qBiTorrent / Transmission

- From backend, Run below commands

```
# docker exec -it transmission bash # Get inside transmission container, OR
docker exec -it qbittorrent bash # Get inside qBittorrent container

mkdir /downloads/movies /downloads/tvshows
chown 1000:1000 /downloads/movies /downloads/tvshows
```

# Add indexer to Jackett

- Open Jackett UI at http://localhost:9117
- Add indexer
- Search for torrent indexer (e.g. the pirates bay, YTS)
- Add selected

# Configure Radarr

- Open Radarr at http://localhost:7878
- Settings --> Media Management --> Check mark "Movies deleted from disk are automatically unmonitored in Radarr" under File management section --> Save
- Settings --> Indexers --> Add --> Add Rarbg indexer --> Add minimum seeder (4) --> Test --> Save
- Settings --> Indexers --> Add --> Torznab --> Follow steps from Jackett to add indexer
- Settings --> Download clients --> Transmission --> Add Host (transmission / qbittorrent) and port (9091 / 5080) --> Username and password if added --> Test --> Save **Note: If VPN is enabled, then transmission / qbittorrent is reachable on vpn's service name**
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

# Configure Prowlarr

- Open Prowlarr at http://localhost:9696
- Settings --> General --> Authentications --> Select AUthentication and add username and password
- Add Indexers, Indexers --> Add Indexer --> Search for indexer --> Choose base URL --> Test and Save
- Add application, Settings --> Apps --> Add application --> Choose Sonarr or Radarr or any apps to link --> Prowlarr server (http://localhost:9696) --> Radarr server (http://localhost:7878) --> API Key --> Test and Save
- This will add indexers in respective apps automatically.

# Apply SSL in Nginx

- Open port 80 and 443.
- Get inside Nginx container and install certbot and certbot-nginx `apk add certbot certbot-nginx`
- Add URL in server block. e.g. `server_name  localhost armdev.navratangupta.in;` in /etc/nginx/conf.d/default.conf
- Run `certbot --nginx` and provide details asked.


# Configure Nginx

- Get inside Nginx container
- `cd /etc/nginx/conf.d`
- Add proxies as per below for all tools.
- OR, copy nginx.conf file to /etc/nginx/conf.d/default.conf and make necessary changes

`docker cp nginx.conf nginx:/etc/nginx/conf.d/default.conf && docker exec -it nginx nginx -s reload`
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

# Sonarr Nginx reverse proxy

- Settings --> General --> URL Base --> Add base (/sonarr)
- Add below proxy in nginx configuration

```
location /radarr {
    proxy_pass http://sonarr:8989;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
  }
```

# Prowlarr Nginx reverse proxy

- Settings --> General --> URL Base --> Add base (/prowlarr)
- Add below proxy in nginx configuration

This may need to change configurations in indexers and base in URL.

```
location /prowlarr {
    proxy_pass http://prowlarr:9696;
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

**Note: If VPN is enabled, then transmission is reachable on vpn's service name**

# qBittorrent Nginx proxy

```
location /qbt/ {
    proxy_pass         http://qbittorrent:5080/;
    proxy_http_version 1.1;

    proxy_set_header   Host               http://qbittorrent:5080;
    proxy_set_header   X-Forwarded-Host   $http_host;
    proxy_set_header   X-Forwarded-For    $remote_addr;
    proxy_cookie_path  /                  "/; Secure";
}
```

**Note: If VPN is enabled, then qbittorrent is reachable on vpn's service name**

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
