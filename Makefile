build:
	docker build . -t saadbruno/minecraft-discord-webhook

push:
	docker push saadbruno/minecraft-discord-webhook:latest
