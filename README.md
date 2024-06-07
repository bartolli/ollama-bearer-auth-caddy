# Ollama Behind Caddy Proxy

Caddy server to securely authenticate and proxy requests to a local Ollama instance, utilizing environment-based API key validation for enhanced security.

## Features

- **Secure API Access**: Uses Caddy to enforce API key authentication, allowing only requests with valid `Bearer` token/api-key.
- **API Key Validation**: Validates API keys from a configuration file using a bash script.
- **Flexible Interaction**: Supports all endpoints to interact with the Ollama API.
- **Dockerized Setup**: Both Ollama and Caddy are containerized.
- **Latest Versions**: Utilizes the latest versions of Ollama and Caddy, ensuring the setup benefits from the most recent updates, security patches, and features. Docker image is configured to pull the latest versions automatically.
- **GPU Support**: Based on NVIDIA CUDA 12.5.0-runtime-ubuntu22.04, optimized for GPU-accelerated host machines.
- **Multi-Platform Architecture**: Supports building for both linux/amd64 and linux/arm64.

## Requirements

- Docker
- Docker Compose or Docker Buildx tool (optional)
- openssl (optional)

## Run the container directly with Docker

To run the container directly using the pre-built image from Docker Hub without Docker Compose and mounth `valid_keys.conf`, use the command below. **Do not forget to generate new valid API keys and update the key file**:

```bash
docker run -p 8081:8081 -v Caddy/valid_keys.conf:/etc/caddy/valid_keys.conf bartolli497/ollama-bearer-auth:cuda-socat
```

**Replace the keys in `Caddy/valid_keys.conf` with the actual API keys you generated.**

- **`-p 8081:8081`**: Maps port 8081 on your local machine to port 8081 in the container. Change to your preferences.
- **`-v Caddy/valid_keys.conf:/etc/caddy/valid_keys.conf`**: Maps the `Caddy/valid_keys.conf` on your host to `/etc/caddy/valid_keys.conf` path in your container.
- **`bartolli497/ollama-bearer-auth:cuda-socat`**: Specifies the Docker image to use, pulling it from Docker Hub.

Mount existing Ollama models from your host machine (optional)

```bash
docker run -p 8081:8081 -v Caddy/valid_keys.conf:/etc/caddy/valid_keys.conf -v ~/.ollama:/root/.ollama bartolli497/ollama-bearer-auth:cuda-socat
```

- **`-v ~/.ollama:/root/.ollama`**: Maps the `~/.ollama` directory on your host to the `/root/.ollama` directory in the container, ensuring necessary files are available.
- **`-v ollama_docker_volume:/root/.ollama`**: Mounts a volume to store and keep all Ollama models outside the container, so you don't have to download them anytime you restart the container.

Note for Windows Users

On Linux and macOS, the manifests use colons (":") in filenames, which are not permitted on Windows filesystems. Therefore, if your host machine is running Windows, you might encounter issues with these filenames.

Read more here: [Issue 2032](https://github.com/ollama/ollama/issues/2032)
and here: [Issue 2832 Comment](https://github.com/ollama/ollama/issues/2832#issuecomment-1994889376)

Mount a volume to store and keep all Ollama models outside the container

## Build your own

Clone the repository:

```bash
git clone https://github.com/bartolli/ollama-bearer-auth-caddy.git
cd ollama-bearer-auth-caddy
```

## Configuration

To customize the server behavior and update the API key, you can modify the ports in the `Caddyfile` (do not change anything else). You MUST change the keys in `valid_keys.conf` file. You can use the key-generator below.

## Generating a secure API Key

To generate a secure API key, you can use a cryptographic random method. This ensures the key is both unique and secure. Make sure you have `openssl` installed on your machine. You can generate the key with the following one-liner, adjust the `sk-ollama-` prefix to whatever you want:

```bash
echo "sk-ollama-$(openssl rand -hex 16)"
```

This should generate something like this:

```bash
sk-ollama-78834bcb4c76d97d35a0c1acd0d938c6
```

Copy the generated key and update your `valid_keys.conf` file with the new API key. You can add as many keys as you need. One key per line.

## Build and run the services using Docker Compose

This command will build multi-architecture image for both linux/amd64 and linux/arm64 architectures

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t <your_username>/<image_name>:<tag> .
```

## Testing API Key Authentication

### Test with incorrect API Key

Test the server's response with an incorrect API key. This should return a `401 Unauthorized` status:

```bash
curl -i http://localhost:8081 -H "Authorization: Bearer wrong_api_key"
```

### Test with correct API Key

Now use the API key generated earlier. This should return a `200 OK` status:

```bash
curl -i http://localhost:8081 -H "Authorization: Bearer correct_api_key"
```

Replace `correct_api_key` with the actual API key you generated.

Note: This project is a modified and improved clone of [ollama-auth](https://github.com/g1ibby/ollama-auth), which originally used a basic auth configuration and a fixed version of Caddy. This enhanced version leverages environment-based API key validation for enhanced security and automatically pulls the latest versions of both Ollama and Caddy.
