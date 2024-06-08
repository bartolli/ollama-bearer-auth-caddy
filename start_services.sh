#!/bin/bash

# Define log file
LOG_FILE="/var/log/service_monitor.log"

# Read the API keys from the file
# API_KEYS=$(cat /etc/caddy/valid_keys.conf)

# Set the OLLAMA_API_KEY environment variable for the current session
# export OLLAMA_API_KEY="$API_KEYS"

# Append the export command to the .bashrc file to persist the variable
# echo 'export OLLAMA_API_KEY="'$API_KEYS'"' >> ~/.bashrc

# Source the .bashrc file to apply the changes to the current session
source ~/.bashrc

# Print the OLLAMA_API_KEY environment variable to confirm it's set
# echo $OLLAMA_API_KEY

# Create log directory for Caddy
mkdir -p /var/log/caddy
chown caddy:caddy /var/log/caddy

echo "Starting all services..." >> "$LOG_FILE"

# Start Ollama in the background
ollama serve &
OLLAMA_PID=$!
echo "$(date): Started Ollama with PID $OLLAMA_PID" >> "$LOG_FILE"

# Start Caddy in the background
caddy run --config /etc/caddy/Caddyfile &
CADDY_PID=$!
echo "$(date): Started Caddy with PID $CADDY_PID" >> "$LOG_FILE"

# Start Uvicorn with FastAPI app
uvicorn app.main:app --host 0.0.0.0 --port 9090 &
UVICORN_PID=$!
echo "$(date): Started Uvicorn with PID $UVICORN_PID" >> "$LOG_FILE"

# Function to check process status
check_process() {
    wait $1
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        echo "$(date): Process $2 ($1) has exited with status $STATUS" >> "$LOG_FILE"
        exit $STATUS
    fi
}

# Handle shutdown signals
trap "echo 'Received shutdown signal, stopping all services...' >> $LOG_FILE; kill $OLLAMA_PID $CADDY_PID $UVICORN_PID; exit 0" SIGTERM SIGINT

# Wait for all services to start and monitor them
while true; do
    if ! ps -p $OLLAMA_PID > /dev/null; then
        echo "$(date): Ollama service is not running, checking for exit status" >> "$LOG_FILE"
        check_process $OLLAMA_PID "Ollama"
        # Only restart if check_process hasn't exited the script
        echo "$(date): Restarting Ollama now" >> "$LOG_FILE"
        ollama serve &
        OLLAMA_PID=$!
    fi
    if ! ps -p $CADDY_PID > /dev/null; then
        echo "$(date): Caddy service is not running, checking for exit status" >> "$LOG_FILE"
        check_process $CADDY_PID "Caddy"
        # Only restart if check_process hasn't exited the script
        echo "$(date): Restarting Caddy now" >> "$LOG_FILE"
        caddy run --config /etc/caddy/Caddyfile &
        CADDY_PID=$!
    fi
    if ! ps -p $UVICORN_PID > /dev/null; then
        echo "$(date): Uvicorn service is not running, checking for exit status" >> "$LOG_FILE"
        check_process $UVICORN_PID "Uvicorn"
        # Only restart if check_process hasn't exited the script
        echo "$(date): Restarting Uvicorn now" >> "$LOG_FILE"
        uvicorn app.main:app --host 0.0.0.0 --port 9090 &
        UVICORN_PID=$!
    fi
    sleep 1
done