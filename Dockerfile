FROM nvidia/cuda:12.5.0-runtime-ubuntu22.04

# Install dependencies
RUN apt-get update && apt-get install -y wget jq curl socat netcat

# Install Ollama 
RUN curl -fsSL https://ollama.com/install.sh | sh

# Download and install the latest Caddy
RUN LATEST_CADDY_URL=$(wget -qO- "https://api.github.com/repos/caddyserver/caddy/releases/latest" | jq -r '.assets[] | select(.name | endswith("_linux_amd64.tar.gz")).browser_download_url') \
    && wget --no-check-certificate "$LATEST_CADDY_URL" -O caddy.tar.gz \
    && tar -xvf caddy.tar.gz -C /usr/bin caddy \
    && chown root:root /usr/bin/caddy \
    && chmod 755 /usr/bin/caddy

# Copy the Caddyfile and validation scripts to the container
COPY Caddy/Caddyfile /etc/caddy/Caddyfile
COPY Caddy/valid_keys.conf /etc/caddy/valid_keys.conf
COPY Caddy/validate_keys.sh /etc/caddy/validate_keys.sh
RUN chmod +x /etc/caddy/validate_keys.sh


# Set the environment variable for the Ollama host
ENV OLLAMA_HOST=0.0.0.0

# Expose the port that Caddy will listen on
EXPOSE 8081

# Copy a script to start both Ollama and Caddy
COPY start_services.sh /start_services.sh
RUN chmod +x /start_services.sh

# Set the entrypoint to the script
ENTRYPOINT ["/start_services.sh"]
