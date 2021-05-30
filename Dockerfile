FROM alpine:3.7
RUN apk add --no-cache bash curl

WORKDIR /app

COPY minecraft-discord-webhook.sh .

ENV FOOTER_TEXT="Minecraft Server"

CMD ["bash", "-c", "./minecraft-discord-webhook.sh $WEBHOOK_URL ./latest.log $FOOTER_TEXT"]