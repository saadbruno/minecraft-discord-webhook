FROM alpine:3.7
RUN apk add --no-cache bash curl

WORKDIR /app

COPY minecraft-discord-webhook.sh .
COPY ./lang ./lang

CMD ["bash", "-c", "WEBHOOK_URL=$WEBHOOK_URL SERVERLOG=./latest.log LANGUAGE=$LANGUAGE FOOTER=$FOOTER ./minecraft-discord-webhook.sh $WEBHOOK_URL"]