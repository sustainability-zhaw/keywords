# sustainability-keyword-mapping validator
Support-Tool for the ZHAW Sustainability keyword mapping

## Purpose

The sustainability keywords mapping tool provides a web browser interface for mapping ZHAW sustainability keywords to the digital collection.

The mapping process runs in a Docker container and is deployed locally in a web browser on port `80`.

The mapping process is embedded into a docker container that is designed to be hosted *behind* a reverse proxy server. That proxy server maintains authentication and SSL-Termination. Neverthless in the current version the docker container will run on a user local docker installation. Therefore several installation steps are necessary and are discussed further down in this document.

## Production environment

No user interface is implemented. Instead, all setup commands are executed via the command line in a terminal program.

```
docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/sustainability-zhaw/sdg-validation:latest --push .
docker pull ghcr.io/sustainability-zhaw/sdg-validation:latest
```

## Launching the sdg mapping service

One can test the frontend using the following command. 

```
docker run --rm -d -p 8080:80 --name sdgmapping ghcr.io/sustainability-zhaw/sdg-validation:latest
```

## Developoment 

The development environment mounts the frontend code into a caddy container. 

```
docker run --rm -d --network proxynetwork --name devcaddy multimico/caddyhelper:latest
docker exec -it devcaddy /bin/ash
```
