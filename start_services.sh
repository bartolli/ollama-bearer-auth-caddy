#!/bin/bash

# Define log file
LOG_FILE="/var/log/service_monitor.log"

# Create log directory for Caddy
mkdir -p /var/log/caddy
chown caddy:caddy /var/log/caddy

echo "Starting all services..." >> "$LOG_FILE"

chmod +x /etc/caddy/validate_keys.sh

# Start socat in the background to validate API keys
socat TCP-LISTEN:9090,fork,reuseaddr EXEC:'/etc/caddy/validate_keys.sh' & >> "$LOG_FILE"
SOCAT_PID=$!
echo "$(date): Started socat with PID $SOCAT_PID" >> "$LOG_FILE"
echo "$(date): validate_keys.sh invoked" >>  "$LOG_FILE" 2>&1

# Start Ollama in the background
ollama serve &
OLLAMA_PID=$!
echo "$(date): Started Ollama with PID $OLLAMA_PID" >> "$LOG_FILE"

# Start Caddy in the background
caddy run --config /etc/caddy/Caddyfile &
CADDY_PID=$!
echo "$(date): Started Caddy with PID $CADDY_PID" >> "$LOG_FILE"

# Function to check process status
check_process() {
    wait $1
    STATUS=$?
    if [ $STATUS -ne 0; then
        echo "$(date): Process $2 ($1) has exited with status $STATUS" >> "$LOG_FILE"
        exit $STATUS
    fi
}

# Handle shutdown signals
trap "echo 'Received shutdown signal, stopping all services...' >> $LOG_FILE; kill $OLLAMA_PID $CADDY_PID $SOCAT_PID; exit 0" SIGTERM SIGINT

# Wait for both services to start and monitor them
while true; do
    if ! ps -p $OLLAMA_PID > /dev/null; then
        echo "$(date): Ollama service is not running, checking for exit status" >> "$LOG_FILE"
        check_process $OLLAMA_PID "Ollama"
        # Only restart if check_process hasn't exited the script
        echo "$(date): Starting Ollama now" >> "$LOG_FILE"
        ollama serve &
        OLLAMA_PID=$!
    fi
    if ! ps -p $CADDY_PID > /dev/null; then
        echo "$(date): Caddy service is not running, checking for exit status" >> "$LOG_FILE"
        check_process $CADDY_PID "Caddy"
        # Only restart if check_process hasn't exited the script
        echo "$(date): Starting Caddy now" >> "$LOG_FILE"
        caddy run --config /etc/caddy/Caddyfile &
        CADDY_PID=$!
    fi
    if ! ps -p $SOCAT_PID > /dev/null; then
        echo "$(date): Socat service is not running, checking for exit status" >> "$LOG_FILE"
        check_process $SOCAT_PID "Socat"
        # Only restart if check_process hasn't exited the script
        echo "$(date): Restarting socat now" >> "$LOG_FILE"
        socat TCP-LISTEN:9090,fork,reuseaddr EXEC:'/etc/caddy/validate_keys.sh' &
        SOCAT_PID=$!
    fi
    sleep 1
done
