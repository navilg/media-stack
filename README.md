[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/linuxshots)

# media-stack

A self-hosted media ecosystem that combines media management, streaming, AI-powered recommendations, and VPN.

This stack includes:

- **VPN:** For secure and private media downloading
- **Radarr:** For movie management
- **Sonarr:** For TV show management
- **Prowlarr:** A torrent indexer manager for Radarr/Sonarr
- **qBittorrent:** Torrent client for downloading media
- **Seerr:** To manage media requests
- **Jellyfin:** Open-source media streamer
- **Recommendarr:** For AI-powered movie and show recommendations

## Requirements

- Docker version 28.0.1 or later
- Docker compose version v2.33.1 or later
- Older versions may work, but they have not been tested.

## Install media stack

> **⚠️ Important Notice for Jellyseerr/Seerr Users:**
> As of version 3, Jellyseerr and Overseerr have been unified into a single project called **Seerr**.
>
> If you're migrating from Jellyseerr to Seerr:
> - Use the same volume name (`jellyseerr-config`) to preserve your existing configuration and avoid data loss.
> - Before starting the Seerr container, change ownership of the config volume to UID 1000 (Seerr's non-root user), as Jellyseerr previously ran as `root`. Run the following command:
>
> `docker run --rm -v media-stack_jellyseerr-config:/data alpine chown -R 1000:1000 /data`

There are three ways to deploy this stack:

1. **With a VPN** (Recommended)  
2. **Without a VPN**  
3. **With Recommendarr** (An optional tool for AI-generated movie and show recommendations)  

> **NOTE:** If you are installing this stack **without a VPN**, you **must** use the `no-vpn` profile.  
> This requirement prevents accidental or unintentional deployment of media-stack without VPN.  
>  
> Running the `docker compose` command without a profile **will not deploy anything**.  
>  
> Check the installation steps below. 


Before deploying the stack, you must first create a Docker network:  

```bash
docker network create --subnet 172.20.0.0/16 mynetwork
# Update the CIDR range based on your available IP range
```

When VPN is enabled, **qBittorrent** and **Prowlarr** will run behind the VPN for added privacy.  

By default, **NordVPN** is used in `docker-compose.yml`, but you can switch to:

- **ExpressVPN**  
- **SurfShark**  
- **ProtonVPN**  
- **Custom OpenVPN**  
- **WireGuard VPN**

All providers use the **OpenVPN** protocol.

➡️ **Full list of supported VPN providers:** [VPN Providers](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers)

### Configure Your VPN Provider  

Refer to your VPN provider's documentation to generate an **OpenVPN username and password**.  
For setup instructions, check:  
➡️ [Gluetun VPN Setup Guide](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers)

### Enabling VPN in `docker-compose.yml`  

By default, **VPN is disabled** in `docker-compose.yml`. To enable it, simply **comment/uncomment** the required lines in the file.  
The `docker-compose.yml` file includes clear instructions in the comments to guide you through the process.  

Once updated, follow the steps below to deploy the stack with VPN.  

### Deploying the Stack with VPN (NordVPN Example)  

```bash
VPN_SERVICE_PROVIDER=nordvpn OPENVPN_USER=openvpn-username OPENVPN_PASSWORD=openvpn-password SERVER_COUNTRIES=Switzerland RADARR_STATIC_CONTAINER_IP=radarr-container-static-ip SONARR_STATIC_CONTAINER_IP=sonarr-container-static-ip docker compose --profile vpn up -d

# OPTIONAL: Use Nginx as a reverse proxy
# docker compose -f docker-compose-nginx.yml up -d
```  

### Static Container IP Requirement  

A **static container IP address** is needed when **Prowlarr** is behind a VPN.  
Since Prowlarr can only communicate with **Radarr** and **Sonarr** using their **container IP addresses**,  
these must be **manually assigned** to avoid connection issues when containers restart.  

Use the following environment variables to set static IPs:  

- `RADARR_STATIC_CONTAINER_IP`  
- `SONARR_STATIC_CONTAINER_IP`  

## Deploy the Stack Without VPN  

🚨 **Warning:** Deploying without a VPN is **highly discouraged** as it may expose your IP address when torrenting media.  

To proceed without VPN, run the following command:  

```bash
docker compose --profile no-vpn up -d

# OPTIONAL: Use Nginx as a reverse proxy
# docker compose -f docker-compose-nginx.yml up -d
```

## Deploy the Stack with Recommendarr (Optional)  

**Recommendarr** is a web application that uses AI to generate personalized TV show and movie recommendations based on your: 

- **Sonarr** library  
- **Radarr** library 
- **Jellyfin** watchlist and library
- **Trakt** watchlist (Optional)

### Deploying with Recommendarr  

Run the following command based on your setup:  

```bash
COMPOSE_PROFILES=vpn,recommendarr docker compose up -d  # With VPN

# COMPOSE_PROFILES=no-vpn,recommendarr docker compose up -d  # Without VPN
```

## Configure qBittorrent

- Open qBitTorrent at http://localhost:5080. Default username is `admin`. Temporary password can be collected from container log `docker logs qbittorrent`
- Go to Tools --> Options --> WebUI --> Change password
- Run below commands on the server

```bash
docker exec -it qbittorrent bash # Get inside qBittorrent container

# Above command will get you inside qBittorrent interactive terminal, Run below command in qbt terminal
mkdir /downloads/movies /downloads/tvshows
chown 1000:1000 /downloads/movies /downloads/tvshows
```

## Configure Radarr

- Open Radarr at http://localhost:7878
- Settings --> Media Management --> Check mark "Movies deleted from disk are automatically unmonitored in Radarr" under File management section --> Save
- Settings --> Media Management --> Scroll to bottom --> Add Root Folder --> Browse to /downloads/movies --> OK
- Settings --> Download clients --> qBittorrent --> Add Host (qbittorrent) and port (5080) --> Username and password --> Test --> Save **Note: If VPN is enabled, then qbittorrent is reachable on vpn's service name. In this case use `vpn` in Host field.**
- Settings --> General --> Enable advance setting --> Select Authentication and add username and password
- Indexer will get automatically added during configuration of Prowlarr. See 'Configure Prowlarr' section.

Sonarr can also be configured in similar way.

**Add a movie** (After Prowlarr is configured)

- Movies --> Search for a movie --> Add Root folder (/downloads/movies) --> Quality profile --> Add movie
- All queued movies download can be checked here, Activities --> Queue 
- Go to qBittorrent (http://localhost:5080) and see if movie is getting downloaded (After movie is queued. This depends on availability of movie in indexers configured in Prowlarr.)

## Configure Jellyfin

- Open Jellyfin at http://localhost:8096
- When you access the jellyfin for first time using browser, A guided configuration will guide you to configure jellyfin. Just follow the guide.
- Add media library folder and choose /data/movies/

## Configure Seerr

- Open Jellyfin at http://localhost:5055
- When you access the seerr for first time using browser, A guided configuration will guide you to configure seerr. Just follow the guide and provide the required details about sonarr and Radarr.
- Follow the Seerr document for detailed setup - https://docs.seerr.dev/

## Configure Prowlarr

- Open Prowlarr at http://localhost:9696
- Settings --> General --> Authentications --> Select Authentication and add username and password
- Add Indexers, Indexers --> Add Indexer --> Search for indexer --> Choose base URL --> Test and Save
- Add application, Settings --> Apps --> Add application --> Choose Radarr --> Prowlarr server (http://prowlarr:9696) --> Radarr server (http://radarr:7878) --> API Key --> Test and Save
- Add application, Settings --> Apps --> Add application --> Choose Sonarr --> Prowlarr server (http://prowlarr:9696) --> Sonarr server (http://sonarr:8989) --> API Key --> Test and Save
- This will add indexers in respective apps automatically.

**Note: If VPN is enabled, then Prowlarr will not be able to reach radarr and sonarr with localhost or container service name. In that case use static IP for sonarr and radarr in radarr/sonarr server field (for e.g. http://172.19.0.5:8989). Prowlar will also be not reachable with its container/service name. Use `http://vpn:9696` instead in prowlar server field.**

## Configure Recommendarr

Recommendarr is an AI based movies/tvshows recommendation tool. To use this you will need any OpenAI API URL and API key with atleast one LLM model running. You can host your own OpenAI server with AI model using ollama or LM Studio. Or you can check `https://openrouter.ai` for limited-free LLMs.

- Open Recommendarr at http://localhost:3000
- Login with default username `admin` and password `1234`
- Settings --> Account --> Change Password and change your admin password
- Settings --> AI service --> API URL (Add OpenAI server API URL) --> API Key (Add OpenAPI server API key) --> Fetch available models --> Set Max tokens (best to keep it under 2000) --> Set Temperature (Best to keep at 0.8)
- Settings --> Sonarr --> Sonarr URL (http://sonarr:8989) --> API Keys (Sonarr API Key) --> Test Connection --> Save Sonarr setting
- Settings --> Radarr --> Radarr URL (http://radarr:7878) --> API Keys (Radarr API Key) --> Test Connection --> Save Radarr setting
- Settings --> Jellyfin --> Jellyfin URL (http://jellyfin:8096) --> API Keys (Jellyfin API Key) --> User ID (Add your jellyfin user id) --> Test Connection --> Save Jellyfin settings
- Test recommendarr: Recommendations --> Choose LLM Model from drop down list --> Enable Jellyfin Watch History toggle --> Select language --> Choose genres --> Discover recommendations
- You should be able to see recommendations based on your Jellyfin watch history

## Configure Nginx

- Get inside Nginx container
- `cd /etc/nginx/conf.d`
- Add proxies for all tools.

`docker cp nginx.conf nginx:/etc/nginx/conf.d/default.conf && docker exec -it nginx nginx -s reload`
- Close ports of other tools in firewall/security groups except port 80 and 443.


## Apply SSL in Nginx

- Open port 80 and 443.
- Get inside Nginx container and install certbot and certbot-nginx `apk add certbot certbot-nginx`
- Add URL in server block. e.g. `server_name  localhost mediastack.example.com;` in /etc/nginx/conf.d/default.conf
- Run `certbot --nginx` and provide details asked.

## Radarr Nginx reverse proxy

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

## Sonarr Nginx reverse proxy

- Settings --> General --> URL Base --> Add base (/sonarr)
- Add below proxy in nginx configuration

```
location /sonarr {
    proxy_pass http://sonarr:8989;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
  }
```

## Prowlarr Nginx reverse proxy

- Settings --> General --> URL Base --> Add base (/prowlarr)
- Add below proxy in nginx configuration

This may need to change configurations in indexers and base in URL.

```
location /prowlarr {
    proxy_pass http://prowlarr:9696; # Comment this line if VPN is enabled.
    # proxy_pass http://vpn:9696; # Uncomment this line if VPN is enabled.
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
  }
```

- Restart containers.

**Note: If VPN is enabled, then Prowlarr is reachable on vpn's service name**

## qBittorrent Nginx proxy

```
location /qbt/ {
    proxy_pass         http://qbittorrent:5080/; # Comment this line if VPN is enabled.
    # proxy_pass         http://vpn:5080/; # Uncomment this line if VPN is enabled.
    proxy_http_version 1.1;

    proxy_set_header   Host               http://qbittorrent:5080; # Comment this line if VPN is enabled.
    # proxy_set_header   Host               http://vpn:5080; # Uncomment this line if VPN is enabled.
    proxy_set_header   X-Forwarded-Host   $http_host;
    proxy_set_header   X-Forwarded-For    $remote_addr;
    proxy_cookie_path  /                  "/; Secure";
}
```

**Note: If VPN is enabled, then qbittorrent is reachable on vpn's service name**

## Jellyfin Nginx proxy

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

## Seerr Nginx proxy

**Currently Seerr doesnot officially support the subfolder/path reverse proxy. They have a workaround documented here without an official support. Find it [here](https://docs.seerr.dev/extending-seerr/reverse-proxy)**

```
location / {
        proxy_pass http://127.0.0.1:5055;

        proxy_set_header Referer $http_referer;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Real-Port $remote_port;
        proxy_set_header X-Forwarded-Host $host:$remote_port;
        proxy_set_header X-Forwarded-Server $host;
        proxy_set_header X-Forwarded-Port $remote_port;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Ssl on;
    }
```

- Restart containers


## Disclaimer  

> Neither the author nor the developers of the code in this repository **condone or encourage** downloading, sharing, seeding, or peering of **copyrighted material**.  
> Such activities are **illegal** under international laws.  
>
> This project is intended for **educational purposes only**.  
