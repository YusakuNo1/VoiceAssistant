# Load .env variables
set -a
source .env
set +a

# Build the docker image
docker build --platform=linux/x86_64 -t ewo-voiceassistant --build-arg AZURE_OPENAI_CHAT_ENDPOINT=${AZURE_OPENAI_CHAT_ENDPOINT} --build-arg AZURE_OPENAI_VISION_ENDPOINT=${AZURE_OPENAI_VISION_ENDPOINT} --build-arg AZURE_AI_EMBEDDINGS_ENDPOINT=${AZURE_AI_EMBEDDINGS_ENDPOINT} . 
