# Demo

This demonstrates how to wire up louketo with keycloak.

## Quickstart

```
docker-compose up -d
```

Watch the logs with `docker-compose logs -f`.

After everything has started, point your browser to

+ https://whoami.localhost (you should see your request)
+ https://keycloak.localhost (you should see keycloak - log in with `admin` and `password`)
+ https://whoami.localhost/get (you should be redirected to keycloak, where you have to login)

## Logging in as a user

A user with

+ username = `user`
+ password = `password`

has been automatically created for you (see `./config/keycloak/setup.sh`)

## Network diagram

> TODO add network diagram for this mini network

## Config

> TODO describe configuration done for each service

## Developer Tips

1. If you're on linux, `*.localhost` redirects to localhost, so you don't have
   to fiddle with DNS or `/etc/hosts`
2. You can get chrome to accept self-signed SSL certs on localhost. Just enable
   this chrome flag: chrome://flags/#allow-insecure-localhost
