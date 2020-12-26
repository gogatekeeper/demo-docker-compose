# Demo

This demonstrates how to wire up gatekeeper with keycloak.

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

![network-diagram.svg](network-diagram.svg)

We use docker-compose to bring up a group of services in this demo - keycloak,
gatekeeper and whoami. This setup uses the OAuth 2.0 Authorization Code flow.

+ whoami is a simple service that echoes the content of the request.
    + whoami allows us to inspect the contents of the request, especially the
        headers that were inserted by gatekeeper
    + whoami serves as the app that you want to add authentication and authorization for
    + in OAuth terms, whoami is half of a resource server: the resource in the resource server
+ keycloak is, in OAuth terms, our authorization provider
    + gatekeeper needs to be able to communicate with keycloak's well-known
      configuration endpoint over https to get keycloak's public key. The
      public key will be used to verify any tokens in requests
+ gatekeeper guards the app, whoami
    + In OAuth terms, gatekeeper is both
        + a client, because it handles exchanging the authorization code for
          the access token with the authorization provider (Keycloak) and
          handles token refreshing
        + half of a resource server, because it checks for a valid access token
          before permitting access to the upstream app (whoami)
    + This two-in-one nature is pretty common - [Ambassador's OAuth2
      filter](https://www.getambassador.io/docs/latest/topics/using/filters/oauth2/)
      does this too
+ caddy is present mostly as a convenient
    + request router: it allows both keycloak and whoami (the app) to appear to
      run on port 443 to the browser on your host
    + tls certificate provider: caddy provides a self-signed a certificate to
      terminate TLS for both keycloak and the app
        + gatekeeper, by design, must make HTTPS connections to the authorization provider
        + gatekeeper does this by calling Keycloak through caddy

In your production setup, you should

+ have Keycloak as a central service external to your app
+ establish trust between gatekeeper and your app, such as
    + by putting gatekeeper and your app in a docker network and allow network
      access to your app only through gatekeeper
    + using firewalls to only allow network access to your app through gatekeeper
    + using [mTLS](https://developers.cloudflare.com/access/service-auth/mtls)
      between gatekeeper and your app

In short, you should only allow access to your app through gatekeeper. This
ensures that

+ all accesses to your app are authenticated and authorized by gatekeeper
+ your app can rely on gatekeeper completely for authentication and authorization

## Config

### Keycloak

> See `./config/keycloak/setup.sh` for all the config that was done

+ An `applications` realm is created. `whoami` will be added as a client in this realm
+ A user is created in the applications realm

### whoami

> See `./config/gatekeeper/setup.sh` for all the config that was done

+ whoami is added as a client (client in OAuth2 terms)
+ whoami has `redirectUris` set to `https://whoami.localhost/oauth/callback*`
    + If Keycloak only accepts `redirectUris` pointing back to `whoami`, we can
      be sure that attackers cannot abuse the `whoami` client to collect auth
      codes by redirecting clients to malicious servers that are
      attacker-controlled
+ The `defaultClientScopes` set means if our user has profile information,
  email or roles set, Keycloak will include this information in the token
    + Inspect what each client scope maps into the token by looking at `Client
      Scopes` on the left navbar on Keycloak
+ The `optionalClientScopes` set means that the `whoami` client can optionally
  request for `address` or `phone` using `--scopes` in gatekeeper, and the mappers
  associated with the `address` or `phone` scopes will be applied on the token

> Inspect your token: point your browser to https://whoami.localhost/get, then
> copy `X-Auth-Token` and inspect it at [jwt.io](https://jwt.io)

+ Add a client scope for `whoami`, with a mapper that maps the client name
  (`whoami`) into the `aud` field of the token
    + gatekeeper checks that the access token has `whoami` in the `aud` field
      before permitting it
+ Associates this client scope with the client `whoami`

+ Adds any requested client roles (in this case `read` and `write`)
    + Client roles can be used for authorization rules in gatekeeper

### gatekeeper

Most of gatekeeper's config is in `./config/gatekeeper/config.yml`, except for
`--client-secret`, which is specified on the command line in
`./config/gatekeeper/start.sh`

Look in `./config/gatekeeper/config.yml` for commented configuration!

## Developer Tips

1. If you're on linux, `*.localhost` redirects to localhost, so you don't have
   to fiddle with DNS or `/etc/hosts`
2. You can get chrome to accept self-signed SSL certs on localhost. Just enable
   this chrome flag: chrome://flags/#allow-insecure-localhost
