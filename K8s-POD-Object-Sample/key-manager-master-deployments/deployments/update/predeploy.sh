#!/usr/bin/env bash

find "${ENV_SCRIPT_PATH}"/scripts/ -type f | grep '\.sh' | xargs chmod +x

if [ -z "$CONSUL_ENABLED" ]; then
  echo "CONSUL_ENABLED is not set. Skip consul integration"
  exit 0
fi

if [ -z "$CONSUL_ADMIN_TOKEN" ]; then
  echo "CONSUL_ADMIN_TOKEN is empty. Skip consul integration"
  exit 0
fi

if [ -z "$CONSUL_PUBLIC_URL" ]; then
  echo "CONSUL_PUBLIC_URL is empty. Skip consul integration"
  exit 0
fi

if ! ( "${ENV_SCRIPT_PATH}"/scripts/prepare_consul.sh ); then
    echo "Failed to apply prepare consul script"
    exit 121
fi
