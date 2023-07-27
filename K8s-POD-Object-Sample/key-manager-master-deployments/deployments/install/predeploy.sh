#!/usr/bin/env bash

find "${ENV_SCRIPT_PATH}"/scripts/ -type f | grep '\.sh' | xargs chmod +x

if [[ -z "$CONSUL_ENABLED" ]] || [[ "$CONSUL_ENABLED" = false ]]; then
  echo "CONSUL_ENABLED is not set. Skip consul integration"
  exit 0
elif [ -z "$CONSUL_PUBLIC_URL" ]; then
  echo "You must set CONSUL_PUBLIC_URL if CONSUL_ENABLED is set"
  exit 121
elif [ -z "$CONSUL_ADMIN_TOKEN" ]; then
    echo "You must set CONSUL_ADMIN_TOKEN if CONSUL_PUBLIC_URL is set"
    exit 121
fi

if ! ( "${ENV_SCRIPT_PATH}"/scripts/prepare_consul.sh ); then
    echo "Failed to apply prepare consul script"
    exit 121
fi
