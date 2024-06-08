# Stage 1: Base Image with CUDA
FROM nvidia/cuda:12.5.0-runtime-ubuntu22.04 AS base

# Install dependencies including Python and Pip
RUN apt-get update && \
    apt-get install -y wget jq curl netcat python3 python3-pip

# Install additional Python libraries needed for FastAPI
RUN pip3 install fastapi uvicorn

# Stage 2: Build Caddy with Plugin
FROM caddy:2.8.4-builder AS caddy-builder

RUN xcaddy build

# Stage 3: Final Image
FROM base 

# Copy Caddy binary from the 'caddy-builder' stage
COPY --from=caddy-builder /usr/bin/caddy /usr/bin/caddy

# Install Ollama 
RUN curl -fsSL https://ollama.com/install.sh | sh

# Copy configuration files 
COPY Caddy/Caddyfile /etc/caddy/Caddyfile
COPY Caddy/valid_keys.conf /etc/caddy/valid_keys.conf

ENV OLLAMA_HOST=0.0.0.0 

# Expose the port 
EXPOSE 8081

# Copy the startup script
COPY start_services.sh /start_services.sh
RUN chmod +x /start_services.sh

# Copy Uvicorn FastAPI application files for key validation
COPY app /app

# Entrypoint
ENTRYPOINT ["/start_services.sh"] 
