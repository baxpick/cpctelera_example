#!/usr/bin/env bash

# Check if DOCKERHUB_USERNAME and DOCKERHUB_PASSWORD are set
if [[ -z "$DOCKERHUB_USERNAME" ]] || [[ -z "$DOCKERHUB_PASSWORD" ]]; then
  echo "Error: DOCKERHUB_USERNAME and DOCKERHUB_PASSWORD environment variables must be set."
  exit 1
fi

echo "Logging in to Docker Hub..."
docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PASSWORD"
if [[ $? -ne 0 ]]; then
  echo "Error: Docker Hub login failed."
  exit 1
fi
echo "Docker Hub login successful."

echo "Building Docker image..."
FULL_IMAGE="braxpix/cpctelera-build-$(arch)-cpc:1.0"
docker build -f Dockerfile.cpc -t ${FULL_IMAGE} .
if [[ $? -ne 0 ]]; then
  echo "Error: Docker image build failed."
  exit 1
fi
echo "Docker image built successfully."

echo "Pushing Docker images to Docker Hub..."
docker push ${FULL_IMAGE} >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
  echo "Error: Docker image push failed."
  exit 1
fi
echo "Docker image pushed successfully."
