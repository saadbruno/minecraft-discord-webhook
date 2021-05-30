#!/bin/bash

# Minecraft Discord Webhook. A simple, server agnostic, way to push your Minecraft server updates to discord. Works with any server and doesn't need mods and plugins.
# MIT License
# Documentation available at: https://github.com/saadbruno/appendhook
# Usage: ./minecraft-discord.webook.sh <discord webhook url> <path to server.log> <footer text>
# Also available via a Docker image, read the github repo for more information

url=$1
serverlog=$2
footer=$3
cache=$(date +'%Y%m%d')

if [ -z "$url" ]; then
  echo ":: WARNING: No webhook URL was set. Please set it using the WEBHOOK_URL environment variable"
fi

echo "Starting webhooks script with the following info:"
echo ":: URL: $url"
echo ":: Footer: $footer"
echo ":: Server log: $serverlog"

# function to send webhooks to Discord
function webhook() {
    curl -H "Content-Type: application/json" \
        -X POST \
        -d '{"username": "Minecraft",
            "avatar_url" : "https://www.minecraft.net/etc.clientlibs/minecraft/clientlibs/main/resources/android-icon-192x192.png",
            "embeds": [{
                "title": "'"$1"'",
                "color": "'"$2"'",
                "thumbnail": {
                    "url": "'"$3"'"
                },
                "footer": {
                    "text": "'"$footer"'"
                }
            }
            ]}' $url
}

# compact version of the webhook
function webhook_compact() {
    curl -H "Content-Type: application/json" \
        -X POST \
        -d '{"username": "Minecraft",
            "avatar_url" : "https://www.minecraft.net/etc.clientlibs/minecraft/clientlibs/main/resources/android-icon-192x192.png",
            "embeds": [{
                "color": "'"$2"'",
                "author": {
                    "name": "'"$1"'",
                    "icon_url": "'"$3"'"
                }
            }
            ]}' $url
}

# actual loop with parsing of the log
tail -n 0 -F $serverlog | while read line; do

    case $line in

    # match for chat message. If it's chat, we catch it first so we don't trigger false positives later
    *\<*\>*) echo "Chat message" ;;

    # joins and parts
    *joined\ the\ game)
        player=$(echo "$line" | grep -o ": .*" | awk '{print $2}')
        echo "$player joined. Sending webhook..."
        webhook_compact "$player entrou no servidor!" 6473516 "https://minotar.net/helm/$player?v=$cache"
        ;;

    *left\ the\ game)
        player=$(echo "$line" | grep -o ": .*" | awk '{print $2}')
        echo "$player left. Sending webhook..."
        webhook_compact "$player saiu do servidor... :(" 9737364 "https://minotar.net/helm/$player?v=$cache"
        ;;

    # death messages, based on https://minecraft.gamepedia.com/Death_messages
    *was*by* | *was\ burnt*  | *whilst\ trying\ to\ escape* | *whilst\ fighting* | *danger\ zone* | *bang* | *death | *lava* | *flames | *fell* | *fell\ while* | *drowned* | *suffocated* | *blew\ up | *kinetic\ energy | *hit\ the\ ground | *didn\'t\ want\ to\ live* | *withered\ away*)
        player=$(echo "$line" | grep -o ": .*" | awk '{print $2}')
        message=$(echo "$line" | grep -o ": .*" | cut -c 3-)
        echo "$player died. Sending webhook..."
        webhook_compact "$message" 10366780 "https://minotar.net/helm/$player?v=$cache"
        ;;

    # advancements
    *has\ made\ the\ advancement*|*completed\ the\ challenge*|*reached\ the\ goal*)
        player=$(echo "$line" | grep -o ": .*" | awk '{print $2}')
        message=$(echo "$line" | grep -o ": .*" | cut -c 3-)
        echo "$player made an advancement! Sending webhook..."
        webhook_compact "$message" 2842864 "https://minotar.net/helm/$player?v=$cache"
        ;;

    esac
done
