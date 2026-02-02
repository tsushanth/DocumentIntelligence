#!/bin/bash

# GCP Cloud Run Deployment Script
# Prerequisites: gcloud CLI installed and authenticated

# Configuration
PROJECT_ID="your-gcp-project-id"  # Change this
SERVICE_NAME="docint-proxy"
REGION="us-central1"

echo "🚀 Deploying Document Intelligence Proxy to Cloud Run..."

# Build and push container
echo "📦 Building container..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME

# Deploy to Cloud Run
echo "☁️ Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --set-env-vars "OPENAI_API_KEY=$OPENAI_API_KEY,APP_API_KEYS=$APP_API_KEYS" \
  --memory 256Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 10 \
  --concurrency 80

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)')

echo ""
echo "✅ Deployment complete!"
echo "🌐 Service URL: $SERVICE_URL"
echo ""
echo "Update your iOS app's proxy URL to: $SERVICE_URL"
