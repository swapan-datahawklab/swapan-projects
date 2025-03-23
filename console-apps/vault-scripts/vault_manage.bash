#!/bin/bash
# =============================================================================
# Script Name:    vault_management.sh
# Description:    This script manages interactions with HashiCorp Vault,
#                 including loading configuration properties, retrieving
#                 authentication tokens, and fetching secrets.
# Usage:          ./vault_management.sh <path_to_properties_file>
# Prerequisites:  - Bash shell
#                 - curl command-line tool
#                 - A valid properties file with necessary configurations
# Author:         Your Name
# Date:           YYYY-MM-DD
# =============================================================================

# -----------------------------------------------------------------------------
# Function:      load_properties
# Description:   Loads configuration variables from a specified properties file.
# Arguments:     $1 - Path to the properties file.
# Returns:       0 on success, 1 on failure.
# -----------------------------------------------------------------------------
load_properties() {
    local properties_file="$1"

    # Check if the properties file path is provided
    if [ -z "$properties_file" ]; then
        echo "Usage: $0 <path_to_properties_file>"
        return 1
    fi

    # Check if the properties file exists
    if [ ! -f "$properties_file" ]; then
        echo "Error: Properties file '$properties_file' not found."
        return 1
    fi

    # Load variables from the properties file
    source "$properties_file"

    # Check if each required property is defined
    local required_vars=(VAULT_URL VAULT_PATH VAULT_URL1 VAULT_PATH1 VAULT_NAMESPACE ROLE_ID SECRET_ID RESPONSE_KEY RESPONSE_KEY1)
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "Error: Required property '$var' is not defined in the properties file."
            return 1
        fi
    done
}

# -----------------------------------------------------------------------------
# Function:      get_vault_value
# Description:   Retrieves a specific value from Vault by making an HTTP request.
# Arguments:     $1 - Vault server URL.
#                $2 - Vault login path.
#                $3 - JSON string containing headers.
#                $4 - JSON payload for the request.
#                $5 - Key to extract from the JSON response.
# Returns:       Extracted value on success, 1 on failure.
# -----------------------------------------------------------------------------
get_vault_value() {
    local VAULT_ADDR="$1"      # Vault server URL (e.g., http://127.0.0.1:8200)
    local LOGIN_PATH="$2"      # Vault login path (e.g., /v1/auth/approle/login)
    local HEADERPAYLOAD="$3"   # JSON string containing headers
    local PAYLOAD="$4"         # JSON payload for login
    local RESPONSE_KEY="$5"    # Key to extract from the JSON response

    # Parse headers from HEADERPAYLOAD
    local headers=()
    while IFS="=" read -r key value; do
        headers+=("-H" "$key: $value")
    done < <(echo "$HEADERPAYLOAD" | sed -E 's/[{}"]//g' | tr ',' '\n' | sed -E 's/ *: */=/')

    # Make a POST request to the Vault login endpoint
    local RESPONSE
    RESPONSE=$(curl -s -X POST --fail \
        "${headers[@]}" \
        -d "$PAYLOAD" \
        "$VAULT_ADDR$LOGIN_PATH")

    # Check if the response contains an error
    if echo "$RESPONSE" | grep -q '"errors"'; then
        echo "Error logging into Vault: $(echo "$RESPONSE" | sed -n 's/.*"errors":\[\([^]]*\)\].*/\1/p' | sed 's/"//g')"
        return 1
    fi

    # Extract and return the specified value from the response
    local VALUE
    VALUE=$(echo "$RESPONSE" | sed -n "s/.*\"$RESPONSE_KEY\":\"\([^\"]*\)\".*/\1/p")
    if [ -n "$VALUE" ]; then
        echo "$VALUE"
    else
        echo "Failed to retrieve $RESPONSE_KEY from response"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Function:      get_vault_token
# Description:   Authenticates with Vault using AppRole and retrieves a client token.
# Arguments:     $1 - Vault server URL.
#                $2 - Vault login path.
#                $3 - Vault namespace.
#                $4 - AppRole role ID.
#                $5 - AppRole secret ID.
#                $6 - Key to extract from the JSON response (e.g., 'client_token').
# Returns:       Client token on success, 1 on failure.
# -----------------------------------------------------------------------------
get_vault_token() {
    local VAULT_URL="$1"
    local VAULT_PATH="$2"
    local VAULT_NAMESPACE="$3"
    local ROLE_ID="$4"
    local SECRET_ID="$5"
    local RESPONSE_KEY="$6"

    local VAULT_FULL_PATH="$VAULT_URL$VAULT_PATH"
    local HEADERPAYLOAD='{"Content-Type": "application/json", "x-vault-namespace": "'$VAULT_NAMESPACE'"}'
    local PAYLOAD="{\"role_id\": \"$ROLE_ID\", \"secret_id\": \"$SECRET_ID\"}"

    # Call get_vault_value to retrieve the token
    local TOKEN
    TOKEN=$(get_vault_value "$VAULT_FULL_PATH" "$LOGIN_PATH" "$HEADERPAYLOAD" "$PAYLOAD" "$RESPONSE_KEY")
    if [ $? -ne 0 ]; then
        echo "Failed to retrieve token"
        return 1
    fi
    echo "$TOKEN"
}

# -----------------------------------------------------------------------------
# Function:      get_vault_dbid_pass
# Description:   Retrieves a database password from Vault.
# Arguments:     $1 - Vault server URL.
#                $2 - Path to the secret in Vault.
#                $3 - Vault namespace.
#                $4 - Vault authentication token.
#                $5 - Key to extract from the JSON response (e.g., 'password').
# Returns:       Database password on success, 1 on failure.
# -----------------------------------------------------------------------------
get_vault_dbid_pass() {
    local VAULT_URL="$1"
    local VAULT_PATH="$2"
    local VAULT_NAMESPACE="$3"
    local VAULT_TOKEN="$4"
    local RESPONSE_KEY="$5"

    local VAULT_FULL_PATH="$VAULT_URL$VAULT_PATH"
    local HEADERPAYLOAD='{"Content-Type": "application/json", "x-vault-namespace": "'"$VAULT_NAMESPACE"'", "x-vault-token": "'"$VAULT_TOKEN"'"}'

    # Call get_vault_value to retrieve the password
    local PASSWORD
    PASSWORD=$(get_vault_value "$VAULT_FULL_PATH" "$VAULT_PATH" "$HEADERPAYLOAD" "$PAYLOAD" "$RESPONSE_KEY")
    if [ $? -ne 0 ]; then
        echo "Failed to retrieve password"
        return 1
    fi
    echo "$PASSWORD"
}

# Function to generate a sample properties file
generate_properties_file() {
    local properties_file="vault.properties"
    cat <<EOL > "$properties_file"
# Sample Vault Properties File
# ============================
# This file contains configuration properties for interacting with HashiCorp Vault.
# Edit the values as needed.

# Vault server URL
VAULT_URL=https://vault.example.com

# Path to the secret in Vault
VAULT_PATH=/path/to/secret

# Additional Vault server URL (if needed)
VAULT_URL1=https://vault1.example.com

# Additional path to the secret in Vault (if needed)
VAULT_PATH1=/path/to/secret1

# Vault namespace (if using namespaces)
VAULT_NAMESPACE=my-namespace

# Role ID for AppRole authentication
ROLE_ID=my-role-id

# Secret ID for AppRole authentication
SECRET_ID=my-secret-id

# Key to extract the response from the Vault secret
RESPONSE_KEY=my-response-key

# Additional key to extract the response from the Vault secret (if needed)
RESPONSE_KEY1=my-response-key1

# Instructions:
# 1. Replace the placeholder values with your actual Vault configuration.
# 2. Save this file and provide its path as an argument to the script.
#    Example: ./vault_management.sh /path/to/vault.properties
EOL
    echo "Sample properties file '$properties_file' has been generated."
}

# -----------------------------------------------------------------------------
# Function:      get_vaulted_db_passwd
# Description:   Orchestrates the process of loading configuration properties,
#                retrieving a Vault token, and fetching a secret (password)
#                from HashiCorp Vault.
# Arguments:     $1 - Path to the properties file.
# Returns:       Exits with status 0 on success, 1 on failure.
# -----------------------------------------------------------------------------
get_vaulted_db_passwd() {
    if [ "$1" == "--generate-properties" ]; then
        generate_properties_file
        exit 0
    fi

    load_properties "$1"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to load properties." >&2
        exit 1
    fi

    # Retrieve the Vault token
    local TOKEN
    TOKEN=$(get_vault_token "$VAULT_URL" "$VAULT_PATH" "$VAULT_NAMESPACE" "$ROLE_ID" "$SECRET_ID" "$RESPONSE_KEY")
    if [ $? -ne 0 ]; then
        echo "Error: Unable to retrieve Vault token." >&2
        exit 1
    fi

    # Retrieve the password from Vault
    local PASSWORD
    PASSWORD=$(get_vault_dbid_pass "$VAULT_URL1" "$VAULT_PATH1" "$VAULT_NAMESPACE" "$TOKEN" "$RESPONSE_KEY1")
    if [ $? -ne 0 ]; then
        echo "Error: Unable to retrieve password from Vault." >&2
        exit 1
    fi

    # Use the retrieved password as needed
    echo "Retrieved Password: $PASSWORD"
}


#!/bin/bash

# Source the script containing the get_vaulted_db_passwd function
source /path/to/vault_management.sh

# Check if the properties file path is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_properties_file>"
    exit 1
fi

# Call the get_vaulted_db_passwd function and assign its output to DB_PASSWD
DB_PASSWD=$(get_vaulted_db_passwd "$1")

# Check if the function executed successfully
if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve the database password." >&2
    exit 1
fi

# Use the DB_PASSWD variable as needed
echo "Retrieved Database Password: $DB_PASSWD"