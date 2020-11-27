#!/bin/sh

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

"$script_dir"/setup.sh &

# Enable preview features in keycloak
exec /opt/jboss/tools/docker-entrypoint.sh -Dkeycloak.profile=preview
