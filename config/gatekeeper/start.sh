#!/bin/bash

set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

# Add caddy root cert in container for redhat ubi image
echo ">>> Adding cert to system CA store"
[ -f /usr/share/pki/ca-trust-source/anchors/root.crt ] || curl -sSk --output /usr/share/pki/ca-trust-source/anchors/root.crt https://caddy.localhost/root.crt && update-ca-trust

# Download wait-for-it.sh if it doesn't exist
[ -f /tmp/wait-for-it.sh ] || curl -o /tmp/wait-for-it.sh https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && chmod +x /tmp/wait-for-it.sh

# Wait for keycloak to be ready (use a direct connection to the container to
#   test, because caddy (keycloak.localhost) comes up way before the service is
#   ready
/tmp/wait-for-it.sh -t 60 keycloak:8443

# Sets up this client with keycloak
#   client roles will be passed to setup.sh
client_secret=$("$script_dir"/setup.sh whoami read write)

echo ">>> Using client_secret=|$client_secret|"
exec /opt/gatekeeper/gatekeeper --config /gatekeeper/config.yml --client-secret="$client_secret"
