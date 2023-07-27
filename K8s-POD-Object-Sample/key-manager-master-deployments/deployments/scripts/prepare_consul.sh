#!/usr/bin/env bash

function createConsulToken() {
  local policy_name="acl-edit"
  local is_policy_already_exists=$(
    curl -sk -o /dev/null -w "%{http_code}" -X GET "${CONSUL_PUBLIC_URL%/}/v1/acl/policy/name/${policy_name}" \
    --header "X-Consul-Token: ${CONSUL_ADMIN_TOKEN}" \
  )

  if [[ ${is_policy_already_exists} != "200" ]]; then
    local acl_edit_policy_payload=$(
      cat <<EOF
      {
        "Name" : "${policy_name}",
        "Description": "Policy for role and policy editing",
        "Rules": "acl = \"write\""
      }
EOF
    )
    local acl_edit_policy_response_code=$(
        curl -sk -o /dev/null -w "%{http_code}" -X PUT "${CONSUL_PUBLIC_URL%/}/v1/acl/policy" \
        --header "X-Consul-Token: ${CONSUL_ADMIN_TOKEN}" \
        --data "${acl_edit_policy_payload}"
      )

    if [[ ${acl_edit_policy_response_code} != "200" ]]; then
        >&2 echo "Unexpected HTTP status code received from consul, failed to add policy!"
        >&2 echo "Received response from consul ${acl_edit_policy_response_code}"
        exit 121
    fi
    echo "Consul policy added successfully!"
  else
    echo "Consul policy with name='${policy_name}' already exists. Skip creation!"
  fi

  local acl_create_token_payload=$(
    cat <<EOF
    {
      "Description": "key manager bootstrap token",
      "Policies": [{"Name": "${policy_name}"}]
    }
EOF
  )
  local acl_create_token_response=$(
      curl -skL -X PUT "${CONSUL_PUBLIC_URL%/}/v1/acl/token" \
      --header "X-Consul-Token: ${CONSUL_ADMIN_TOKEN}" \
      --data "${acl_create_token_payload}"
  )

  TOKEN=$(echo "${acl_create_token_response}" | jq -r '.SecretID')
  if [ -z "$TOKEN" ]; then
    >&2 echo "can not create token. Skip consul integration."
    exit 121
  fi
}

function saveConsulToken() {
    local token_secret_name="key-manager-consul-token"
    echo "Creating ${token_secret_name} secret"
cat << EOF | oc311 plugin shift_plugin_caller oc_apply_file --file_oc_object=/dev/stdin --shift_namespace="${ENV_NAMESPACE}"
{
    "apiVersion": "v1",
    "kind": "Secret",
    "metadata": {
        "name": "$token_secret_name"
    },
    "data": {
        "token": "$(printf "%s" "$TOKEN" | base64 -w0 )"
    }
}
EOF
    if [ $? -eq 0 ]; then
        echo "Secret ${token_secret_name} has been created successfully"
    else
        >&2 echo "Secret ${token_secret_name} creation has been failed"
        exit 121
    fi
}

createConsulToken
saveConsulToken