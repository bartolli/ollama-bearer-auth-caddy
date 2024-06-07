#!/bin/bash

# Function to log messages with timestamps
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> /var/log/validate_keys.log
}

# Function to send HTTP response
send_response() {
    local status="$1"
    local content="$2"
    local proxy_status="$3"
    printf "HTTP/1.1 %s\r\nContent-Type: text/plain\r\nContent-Length: %d\r\nProxy-Status: %s\r\n\r\n%s" \
           "$status" "${#content}" "$proxy_status" "$content"
}

# Read from standard input to capture HTTP request with a timeout
request=""
while IFS= read -r -t 5 line; do
    request+="$line"$'\r\n'
    if [ -z "$line" ]; then
        break
    fi
done

if [ -z "$request" ]; then
    log "Request read timeout or empty request."
    send_response "408 Request Timeout" "Request Timeout" "request_timeout"
    exit 1
fi

log "Received request: $request"

# Extract the API key from the Authorization header that starts with "Bearer "
API_KEY=$(echo "$request" | grep -oP 'Authorization: Bearer \K[^\r\n]*')

if [ -z "$API_KEY" ]; then
    log "Failed to extract API Key from request: $request"
    send_response "400 Bad Request" "Invalid API Key format" "invalid_api_key_format"
    exit 1
fi

log "Extracted API Key: $API_KEY"

# Path to the file containing valid API keys
KEY_FILE="/etc/caddy/valid_keys.conf"

# Check if the key file exists
if [ ! -f "$KEY_FILE" ]; then
    log "Key file does not exist: $KEY_FILE"
    send_response "500 Internal Server Error" "Key file not found" "key_file_not_found"
    exit 1
fi

# Check if the provided API key exists in the key file
if grep -Fxq "$API_KEY" "$KEY_FILE"; then
    log "API Key validation successful for key: $API_KEY"
    send_response "200 OK" "" "valid_api_key"
    exit 0
else
    log "API Key validation failed for key: $API_KEY"
    send_response "401 Unauthorized" "Invalid API Key" "invalid_api_key"
    exit 1
fi
