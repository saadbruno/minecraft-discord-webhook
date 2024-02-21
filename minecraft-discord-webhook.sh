#!/bin/bash

# Minecraft Discord Webhook. A simple, server agnostic, way to push your Minecraft server updates to discord. Works with any server and doesn't need mods and plugins.
# MIT License
# Documentation available at: https://github.com/saadbruno/appendhook
# Usage:
#    WEBHOOK_URL=<discord webhook> SERVERLOG=</path/to/server/logs> FOOTER=<optional footer> LANGUAGE=<optional language> ./minecraft-discord.webook.sh
# Also available via a Docker image, read the github repo for more information

#let's check for required variables
if [ -z "$WEBHOOK_URL" ]; then
    echo ":: WARNING: Missing arguments. USAGE:"
    echo "   WEBHOOK_URL=<discord webhook> SERVERLOG=</path/to/server/logs> FOOTER=<optional footer> LANGUAGE=<optional language> ./minecraft-discord.webook.sh"
    echo ":: If you're using Docker, make sure you've set the WEBHOOK_URL environment variable"
    exit 1
fi

if [ ! -f "$SERVERLOG/latest.log" ]; then
    echo ":: WARNING: Couldn't find server log. Make sure $SERVERLOG/latest.log exists. USAGE:"
    echo "   WEBHOOK_URL=<discord webhook> SERVERLOG=</path/to/server/logs> FOOTER=<optional footer> LANGUAGE=<optional language> ./minecraft-discord.webook.sh"
    echo ":: If you're using Docker, make sure you mounted your server log to /app/latest.log with '-v /path/to/server/logs/latest.log:/app/latest.log:ro'"
    exit 1
fi

DIR=$(dirname $0)

# cache forces minotar to give us a new avatar every day, in case players change their skins
CACHE=$(date +'%Y%m%d')

# Let's default our language to english
if [ -z "$LANGUAGE" ]; then
    LANGUAGE="en-US"
fi

if [ -z "$BOTNAME" ]; then
    BOTNAME="Minecraft"
fi
if [ -z "$AVATAR" ]; then
    AVATAR="https://www.minecraft.net/etc.clientlibs/minecraft/clientlibs/main/resources/android-icon-192x192.png"
fi


LANGFILE=$DIR/lang/$LANGUAGE.sh
echo "================================================="
echo "Starting webhooks script with the following info:"
echo ":: Language: $LANGUAGE"
echo ":: URL: $WEBHOOK_URL"
echo ":: Footer: $FOOTER"
echo ":: Server logs: $SERVERLOG/latest.log"
echo "================================================="

# compact version of the webhook
function webhook_compact() {
    CONTENT=""
    if [ "$PREVIEW" ]; then
        CONTENT=$1
    fi
    curl -H "Content-Type: application/json" \
        -X POST \
        -d '{
                "username": "'"$BOTNAME"'",
                "avatar_url" : "'"$AVATAR"'",
                "content": "'"$CONTENT"'",
                "embeds": [{
                    "color": "'"$2"'",
                    "author": {
                        "name": "'"$1"'",
                        "icon_url": "'"$3"'"
                    },
                    "footer": {
                        "text": "'"$FOOTER"'"
                    }
                }]
            }' $WEBHOOK_URL
}

# send a message that the service has started
webhook_compact "$0 started monitoring $SERVERLOG/latest.log" 9737364 "$AVATAR"

# actual loop with parsing of the log
tail -n 0 -F $SERVERLOG/latest.log | while read LINE; do
    case $LINE in

    # match for chat message. If it's chat, we catch it first so we don't trigger false positives later
    *\<*\>*) echo "Chat message" ;;

    # joins and parts
    *joined\ the\ game)
        PLAYER=$(echo "$LINE" | grep -o ": .*" | awk '{print $2}')
        source $LANGFILE
        echo "$PLAYER joined. Sending webhook..."
        webhook_compact "$JOIN" 6473516 "https://minotar.net/helm/$PLAYER?v=$CACHE"
        ;;

    *left\ the\ game)
        PLAYER=$(echo "$LINE" | grep -o ": .*" | awk '{print $2}')
        source $LANGFILE
        echo "$PLAYER left. Sending webhook..."
        webhook_compact "$LEAVE" 9737364 "https://minotar.net/helm/$PLAYER?v=$CACHE"
        ;;

    # death messages, based on https://minecraft.gamepedia.com/Death_messages
    *was*by* | *was\ burnt* | *whilst\ trying\ to\ escape* | *whilst\ fighting* | *danger\ zone* | *bang* | *death | *lava* | *flames | *fell* | *fell\ while* | *drowned* | *suffocated* | *blew\ up | *kinetic\ energy | *hit\ the\ ground | *didn\'t\ want\ to\ live* | *withered\ away*)
        PLAYER=$(echo "$LINE" | grep -o ": .*" | awk '{print $2}')
        MESSAGE=$(echo "$LINE" | grep -o ": .*" | cut -c 3-)
        source $LANGFILE
        echo "$PLAYER died. Sending webhook..."
        webhook_compact "$MESSAGE" 10366780 "https://minotar.net/helm/$PLAYER?v=$CACHE"
        ;;

    # advancements
    *has\ made\ the\ advancement* | *completed\ the\ challenge* | *reached\ the\ goal*)
        PLAYER=$(echo "$LINE" | grep -o ": .*" | awk '{print $2}')
        MESSAGE=$(echo "$LINE" | grep -o ": .*" | cut -c 3-)
        source $LANGFILE
        echo "$PLAYER made an advancement! Sending webhook..."
        webhook_compact "$MESSAGE" 2842864 "https://minotar.net/helm/$PLAYER?v=$CACHE"
        ;;

    # Geyser main server messages
    *main\/INFO\]*)
        MESSAGE=$(echo "$LINE" | cut -d "]" -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        source $LANGFILE
        echo "Geyser INFO-message. Sending webhook..."
        webhook_compact "$MESSAGE" 3447003 "https://geysermc.org/img/icons/geyser.png"
        ;;

    # Geyser main server messages
    *main\/WARN\]*)
        MESSAGE=$(echo "$LINE" | cut -d "]" -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        source $LANGFILE
        echo "Geyser WARN-message. Sending webhook..."
        webhook_compact "$MESSAGE" 10366780 "https://geysermc.org/img/icons/geyser.png"
        ;;

    # Geyser client connect
    *tried\ to\ connect*)
        MESSAGE=$(echo "$LINE" | cut -d "]" -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        source $LANGFILE
        echo "Geyser Connect-message. Sending webhook..."
        webhook_compact "$MESSAGE" 3447003 "https://geysermc.org/img/icons/geyser.png"
        ;;

    # Geyser client with stored cred
    *Using\ stored\ credentials*)
        MESSAGE=$(echo "$LINE" | cut -d "]" -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        PLAYER=$(echo "$LINE" | rev | cut -d " " -f 1 | rev)
        source $LANGFILE
        echo "Geyser Cred-message. Sending webhook..."
        webhook_compact "$MESSAGE" 3447003 "https://minotar.net/helm/$PLAYER?v=$CACHE"
        ;;

    # Geyser client successfully connected
    *Player\ connected\ with\ username*)
        MESSAGE=$(echo "$LINE" | cut -d "]" -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        PLAYER=$(echo "$LINE" | rev | cut -d " " -f 1 | rev)
        source $LANGFILE
        echo "Geyser Player-message. Sending webhook..."
        webhook_compact "$MESSAGE" 3447003 "https://minotar.net/helm/$PLAYER?v=$CACHE"
        ;;

    # Geyser client proxied 
    *has\ connected\ to\ remote* | *has\ disconnected\ from\ remote* )
        MESSAGE=$(echo "$LINE" | cut -d "]" -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        PLAYER=$(echo "$MESSAGE" | cut -d " " -f 1)
        source $LANGFILE
        echo "Geyser Player-connected-message. Sending webhook..."
        webhook_compact "$MESSAGE" 3447003 "https://minotar.net/helm/$PLAYER?v=$CACHE"
        ;;

    # Other Geyser server messages
    *\/INFO\]*)
        MESSAGE=$(echo "$LINE" | cut -d "]" -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        source $LANGFILE
        echo "Geyser INFO-message #2. Sending webhook..."
        webhook_compact "$MESSAGE" 3447003 "https://geysermc.org/img/icons/geyser.png"
        ;;

    # Other Geyser server messages
    *\/WARN\]*)
        MESSAGE=$(echo "$LINE" | cut -d "]" -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        source $LANGFILE
        echo "Geyser WARN-message #2. Sending webhook..."
        webhook_compact "$MESSAGE" 10366780 "https://geysermc.org/img/icons/geyser.png"
        ;;

    esac
done
