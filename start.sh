#!/usr/bin/env bash
NEZHA_SERVER=${NEZHA_SERVER:-'nz.f4i.cn'}
NEZHA_PORT=${NEZHA_PORT:-'5555'}
NEZHA_KEY=${NEZHA_KEY:-'cFcBDhXpiNIo8Tjkr1'}
TLS=${TLS:-''}
ARGO_DOMAIN=${ARGO_DOMAIN:-''}
ARGO_AUTH=${ARGO_AUTH:-''}
WSPATH=${WSPATH:-'argo'}
UUID=${UUID:-'de04add9-5c68-8bab-870c-08cd5320df02'}
CFIP=${CFIP:-'skk.moe'}

if [ "$TLS" -eq 0 ]; then
  NEZHA_TLS=''
elif [ "$TLS" -eq 1 ]; then
  NEZHA_TLS='--tls'
fi


set_download_url() {
  local program_name="$1"
  local default_url="$2"
  local x64_url="$3"

  if [ "$(uname -m)" = "x86_64" ] || [ "$(uname -m)" = "amd64" ] || [ "$(uname -m)" = "x64" ]; then
    download_url="$x64_url"
  else
    download_url="$default_url"
  fi
}

download_program() {
  local program_name="$1"
  local default_url="$2"
  local x64_url="$3"

  set_download_url "$program_name" "$default_url" "$x64_url"

  if [ ! -f "$program_name" ]; then
    if [ -n "$download_url" ]; then
      echo "Downloading $program_name..."
      curl -sSL "$download_url" -o "$program_name"
      dd if=/dev/urandom bs=1024 count=1024 | base64 >> "$program_name"
      echo "Downloaded $program_name"
    else
      echo "Skipping download for $program_name"
    fi
  else
    dd if=/dev/urandom bs=1024 count=1024 | base64 >> "$program_name"
    echo "$program_name already exists, skipping download"
  fi
}


download_program "swith" "https://github.com/fscarmen2/X-for-Botshard-ARM/raw/main/nezha-agent" "https://github.com/fscarmen2/X-for-Stozu/raw/main/nezha-agent"
sleep 6

download_program "web" "https://github.com/fscarmen2/X-for-Botshard-ARM/raw/main/web.js" "https://github.com/fscarmen2/X-for-Stozu/raw/main/web.js"
sleep 6

download_program "server" "https://github.com/cloudflare/cloudflared/releases/download/2023.8.0/cloudflared-linux-arm64" "https://github.com/cloudflare/cloudflared/releases/download/2023.8.0/cloudflared-linux-amd64"
sleep 6

cleanup_files() {
  rm -rf boot.log list.txt
}

argo_type() {
  if [[ -z $ARGO_AUTH || -z $ARGO_DOMAIN ]]; then
    echo "ARGO_AUTH or ARGO_DOMAIN is empty, use interim Tunnels"
    return
  fi

  if [[ $ARGO_AUTH =~ TunnelSecret ]]; then
    echo $ARGO_AUTH > tunnel.json
    cat > tunnel.yml << EOF
tunnel: $(cut -d\" -f12 <<< $ARGO_AUTH)
credentials-file: ./tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost:8080
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
  else
    echo "ARGO_AUTH Mismatch TunnelSecret"
  fi
}


run() {
  if [ -e swith ]; then
  chmod 775 swith
    if [ -n "$NEZHA_SERVER" ] && [ -n "$NEZHA_PORT" ] && [ -n "$NEZHA_KEY" ]; then
    nohup ./swith -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_TLS} >/dev/null 2>&1 &
    keep1="nohup ./swith -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_TLS} >/dev/null 2>&1 &"
    fi
  fi

  if [ -e web ]; then
  chmod 775 web
    nohup ./web -c ./config.json >/dev/null 2>&1 &
    keep2="nohup ./web -c ./config.json >/dev/null 2>&1 &"
  fi

  if [ -e server ]; then
  chmod 775 server
if [[ $ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
  args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile boot.log --loglevel info run --token ${ARGO_AUTH}"
elif [[ $ARGO_AUTH =~ TunnelSecret ]]; then
  args="tunnel --edge-ip-version auto --config tunnel.yml run"
else
  args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile boot.log --loglevel info --url http://localhost:8080"
fi
nohup ./server $args >/dev/null 2>&1 &
keep3="nohup ./server $args >/dev/null 2>&1 &"
  fi
} 

generate_config() {
  cat > config.json << EOF
{
    "log":{
        "access":"/dev/null",
        "error":"/dev/null",
        "loglevel":"none"
    },
    "inbounds":[
        {
            "port":8080,
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "flow":"xtls-rprx-vision"
                    }
                ],
                "decryption":"none",
                "fallbacks":[
                    {
                        "dest":3001
                    },
                    {
                        "path":"/vless",
                        "dest":3002
                    },
                    {
                        "path":"/vmess",
                        "dest":3003
                    },
                    {
                        "path":"/trojan",
                        "dest":3004
                    },
                    {
                        "path":"/shadowsocks",
                        "dest":3005
                    }
                ]
            },
            "streamSettings":{
                "network":"tcp"
            }
        },
        {
            "port":3001,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none"
            }
        },
        {
            "port":3002,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "level":0
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"/vless"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3003,
            "listen":"127.0.0.1",
            "protocol":"vmess",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "alterId":0
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"/vmess"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3004,
            "listen":"127.0.0.1",
            "protocol":"trojan",
            "settings":{
                "clients":[
                    {
                        "password":"${UUID}"
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"/trojan"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3005,
            "listen":"127.0.0.1",
            "protocol":"shadowsocks",
            "settings":{
                "clients":[
                    {
                        "method":"chacha20-ietf-poly1305",
                        "password":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"/shadowsocks"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        }
    ],
    "dns":{
        "servers":[
            "https+local://8.8.8.8/dns-query"
        ]
    },
    "outbounds":[
        {
            "protocol":"freedom"
        },
        {
            "tag":"WARP",
            "protocol":"wireguard",
            "settings":{
                "secretKey":"YFYOAdbw1bKTHlNNi+aEjBM3BO7unuFC5rOkMRAz9XY=",
                "address":[
                    "172.16.0.2/32",
                    "2606:4700:110:8a36:df92:102a:9602:fa18/128"
                ],
                "peers":[
                    {
                        "publicKey":"bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
                        "allowedIPs":[
                            "0.0.0.0/0",
                            "::/0"
                        ],
                        "endpoint":"162.159.193.10:2408"
                    }
                ],
                "reserved":[78, 135, 76],
                "mtu":1280
            }
        }
    ],
    "routing":{
        "domainStrategy":"AsIs",
        "rules":[
            {
                "type":"field",
                "domain":[
                    "domain:openai.com",
                    "domain:ai.com"
                ],
                "outboundTag":"WARP"
            }
        ]
    }
}
EOF
}

cleanup_files
sleep 2
generate_config
sleep 3
argo_type
sleep 3
run
sleep 15

function get_argo_domain() {
  if [[ -n $ARGO_AUTH ]]; then
    echo "$ARGO_DOMAIN"
  else
    cat boot.log | grep trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}'
  fi
}

isp=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18"-"$30}' | sed -e 's/ /_/g')
sleep 3

generate_links() {
  argo=$(get_argo_domain)
  sleep 1

  VMESS="{ \"v\": \"2\", \"ps\": \"VMESS-${isp}\", \"add\": \"${CFIP}\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${argo}\", \"path\": \"/vmess?ed=2048\", \"tls\": \"tls\", \"sni\": \"${argo}\", \"alpn\": \"\" }"

  cat > list.txt <<EOF
*******************************************
${CFIP} 可替换为CF优选IP,端口 443 可改为 2053 2083 2087 2096 8443
----------------------------
V2-rayN:
----------------------------
vless://${UUID}@${CFIP}:443?encryption=none&security=tls&sni=${argo}&type=ws&host=${argo}&path=%2Fvless?ed=2048#VLESS-${isp}
----------------------------
vmess://$(echo "$VMESS" | base64 -w0)
----------------------------
trojan://${UUID}@${CFIP}:443?security=tls&sni=${argo}&type=ws&host=${argo}&path=%2Ftrojan?ed=2048#Trojan-${isp}
----------------------------
ss://$(echo "chacha20-ietf-poly1305:${UUID}@${CFIP}:443" | base64 -w0)@${CFIP}:443#SSR-${isp}
由于该软件导出的链接不全，请自行处理如下: 传输协议: WS ， 伪装域名: ${argo} ，路径: /shadowsocks?ed=2048 ， 传输层安全: tls ， sni: ${argo}
*******************************************
Shadowrocket:
----------------------------
vless://${UUID}@${CFIP}:443?encryption=none&security=tls&type=ws&host=${argo}&path=/vless?ed=2048&sni=${argo}#VLESS-${isp}
----------------------------
vmess://$(echo "none:${UUID}@${CFIP}:443" | base64 -w0)?remarks=${isp}-Vm&obfsParam=${argo}&path=/vmess?ed=2048&obfs=websocket&tls=1&peer=${argo}&alterId=0
----------------------------
trojan://${UUID}@${CFIP}:443?peer=${argo}&plugin=obfs-local;obfs=websocket;obfs-host=${argo};obfs-uri=/trojan?ed=2048#Trojan-${isp}
----------------------------
ss://$(echo "chacha20-ietf-poly1305:${UUID}@${CFIP}:443" | base64 -w0)?obfs=wss&obfsParam=${argo}&path=/shadowsocks?ed=2048#SSR-${isp}
*******************************************
Clash:
----------------------------
- {name: ${isp}-Vless, type: vless, server: ${CFIP}, port: 443, uuid: ${UUID}, tls: true, servername: ${argo}, skip-cert-verify: false, network: ws, ws-opts: {path: /vless?ed=2048, headers: { Host: ${argo}}}, udp: true}
----------------------------
- {name: ${isp}-Vmess, type: vmess, server: ${CFIP}, port: 443, uuid: ${UUID}, alterId: 0, cipher: none, tls: true, skip-cert-verify: true, network: ws, ws-opts: {path: /vmess?ed=2048, headers: {Host: ${argo}}}, udp: true}
----------------------------
- {name: ${isp}-Trojan, type: trojan, server: ${CFIP}, port: 443, password: ${UUID}, udp: true, tls: true, sni: ${argo}, skip-cert-verify: false, network: ws, ws-opts: { path: /trojan?ed=2048, headers: { Host: ${argo} } } }
----------------------------
- {name: ${isp}-Shadowsocks, type: ss, server: ${CFIP}, port: 443, cipher: chacha20-ietf-poly1305, password: ${UUID}, plugin: v2ray-plugin, plugin-opts: { mode: websocket, host: ${argo}, path: /shadowsocks?ed=2048, tls: true, skip-cert-verify: false, mux: false } }
*******************************************
EOF

#   cat > encode.txt <<EOF
# vless://${UUID}@${CFIP}:443?encryption=none&security=tls&sni=${argo}&type=ws&host=${argo}&path=%2Fvless?ed=2048#${isp}-Vl
# vmess://$(echo "$VMESS" | base64 -w0)
# trojan://${UUID}@${CFIP}:443?security=tls&sni=${argo}&type=ws&host=${argo}&path=%2Ftrojan?ed=2048#${isp}-Tr
# EOF

# base64 -w0 encode.txt > sub.txt 

  cat list.txt
  echo -e "list.txt file is saveing successfully "
}

generate_links

chmod +x PocketMine--MP.phar
export PATH=/home/container/bin/php7/bin:$PATH
source ~/.bashrc
php ./PocketMine--MP.phar

function start_swith_program() {
if [ -n "$keep1" ]; then
  if [ -z "$pid" ]; then
    echo "course'$program'Not running, starting..."
    eval "$command"
  else
    echo "course'$program'running，PID: $pid"
  fi
else
  echo "course'$program'No need"
fi
}

function start_web_program() {
  if [ -z "$pid" ]; then
    echo "course'$program'Not running, starting..."
    eval "$command"
  else
    echo "course'$program'running，PID: $pid"
  fi
}

function start_server_program() {
  if [ -z "$pid" ]; then
    echo "'$program'Not running, starting..."
    cleanup_files
    sleep 2
    eval "$command"
    sleep 5
    generate_links
    sleep 3
  else
    echo "course'$program'running，PID: $pid"
  fi
}

function start_program() {
  local program=$1
  local command=$2

  pid=$(pidof "$program")

  if [ "$program" = "swith" ]; then
    start_swith_program
  elif [ "$program" = "web" ]; then
    start_web_program
  elif [ "$program" = "server" ]; then
    start_server_program
  fi
}

programs=("swith" "web" "server")
commands=("$keep1" "$keep2" "$keep3")

while true; do
  for ((i=0; i<${#programs[@]}; i++)); do
    program=${programs[i]}
    command=${commands[i]}

    start_program "$program" "$command"
  done
  sleep 180
done