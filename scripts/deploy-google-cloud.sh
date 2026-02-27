#!/usr/bin/env bash
# Deploy OpenHands to Google Cloud Run
# Prerequisites: gcloud CLI, Docker (for local build)
# Usage: ./scripts/deploy-google-cloud.sh [PROJECT_ID] [REGION]

set -e

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"
REGION="${2:-us-central1}"
SERVICE_NAME="${SERVICE_NAME:-openhands}"
REPOSITORY="${REPOSITORY:-openhands}"

if [ -z "$PROJECT_ID" ]; then
  echo "Error: PROJECT_ID required. Usage: $0 PROJECT_ID [REGION]"
  echo "Or set: gcloud config set project YOUR_PROJECT_ID"
  exit 1
fi

echo "Deploying OpenHands to Google Cloud Run"
echo "  Project:   $PROJECT_ID"
echo "  Region:    $REGION"
echo "  Service:   $SERVICE_NAME"
echo ""

# Enable required APIs
echo "Enabling APIs..."
gcloud services enable cloudbuild.googleapis.com run.googleapis.com artifactregistry.googleapis.com --project="$PROJECT_ID" 2>/dev/null || true

# Create Artifact Registry repo if not exists
echo "Ensuring Artifact Registry repository..."
gcloud artifacts repositories describe "$REPOSITORY" --location="$REGION" --project="$PROJECT_ID" 2>/dev/null || \
  gcloud artifacts repositories create "$REPOSITORY" --repository-format=docker --location="$REGION" --project="$PROJECT_ID"

# Build and deploy via Cloud Build
# SHORT_SHA is auto-set by Cloud Build when triggered from repo; use 'latest' for manual submit
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD 2>/dev/null || echo 'latest')}"
echo "Image tag: $IMAGE_TAG"

gcloud builds submit \
  --config=cloudbuild.yaml \
  --project="$PROJECT_ID" \
  --substitutions="_REGION=$REGION,_SERVICE_NAME=$SERVICE_NAME,_REPOSITORY=$REPOSITORY,SHORT_SHA=$IMAGE_TAG"

echo ""
echo "Deployment complete. Get URL:"
echo "  gcloud run services describe $SERVICE_NAME --region=$REGION --format='value(status.url)'"
