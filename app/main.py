from fastapi import FastAPI, Request, Response
import os

app = FastAPI()

# Function to load API keys from the key file
def load_api_keys(file_path):
    try:
        with open(file_path, "r") as file:
            return {line.strip() for line in file if line.strip()}
    except Exception as e:
        print(f"Error reading API keys from file: {e}")
        return set()

# load valid_keys.conf and parse keys
API_KEYS_FILE_PATH = "/etc/caddy/valid_keys.conf"
VALID_API_KEYS = load_api_keys(API_KEYS_FILE_PATH)

@app.api_route("/", methods=["GET", "POST"])  # Add more requests if you want to use with Ollama
async def validate_api_key(request: Request):
    authorization: str = request.headers.get("Authorization", "")
    if not authorization.startswith("Bearer "):
        return Response("Invalid API Key format", status_code=400, headers={"Proxy-Status": "invalid_api_key_format"})

    api_key = authorization[7:]  # Remove the 'Bearer ' prefix
    if api_key in VALID_API_KEYS:
        return Response("API Key validation successful", status_code=200, headers={"Proxy-Status": "valid_api_key"})
    else:
        return Response("Invalid API Key", status_code=401, headers={"Proxy-Status": "invalid_api_key"})
