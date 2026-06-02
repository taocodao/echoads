#!/usr/bin/env bash
# scripts/setup-s3-media.sh
# ─────────────────────────────────────────────────────────────────────────────
# Creates the S3 bucket for CMXS prototype media, configures CORS and public
# read access, then creates a CloudFront distribution.
#
# Prerequisites:
#   - AWS CLI installed and configured (aws configure)
#   - Environment: AWS_REGION, S3_MEDIA_BUCKET set in shell or .env
#
# Usage:
#   export AWS_REGION=us-east-1
#   export S3_MEDIA_BUCKET=cmxs-media-prototype
#   bash scripts/setup-s3-media.sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

BUCKET="${S3_MEDIA_BUCKET:-cmxs-media-prototype}"
REGION="${AWS_REGION:-us-east-1}"

echo "═══════════════════════════════════════════════"
echo "  CMXS Media Infrastructure Setup"
echo "  Bucket : $BUCKET"
echo "  Region : $REGION"
echo "═══════════════════════════════════════════════"

# ── 1. Create S3 bucket ───────────────────────────────────────────────────────
echo ""
echo "▶ Creating S3 bucket..."

if [ "$REGION" = "us-east-1" ]; then
  aws s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$REGION" 2>/dev/null || echo "  (bucket already exists)"
else
  aws s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" 2>/dev/null || echo "  (bucket already exists)"
fi

# ── 2. Disable block-public-access (required for CloudFront OAC) ─────────────
echo "▶ Configuring bucket access..."
aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# ── 3. Bucket policy: public read for all objects ────────────────────────────
echo "▶ Setting public read policy..."
aws s3api put-bucket-policy --bucket "$BUCKET" --policy "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [{
    \"Sid\": \"PublicReadGetObject\",
    \"Effect\": \"Allow\",
    \"Principal\": \"*\",
    \"Action\": \"s3:GetObject\",
    \"Resource\": \"arn:aws:s3:::${BUCKET}/*\"
  }]
}"

# ── 4. CORS for HLS.js browser playback ──────────────────────────────────────
echo "▶ Configuring CORS..."
aws s3api put-bucket-cors --bucket "$BUCKET" --cors-configuration '{
  "CORSRules": [{
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag", "Content-Length"],
    "MaxAgeSeconds": 86400
  }]
}'

# ── 5. Create placeholder directory structure ─────────────────────────────────
echo "▶ Creating folder structure placeholders..."

# Create placeholder README files in each directory
for dir in \
  "content/sports_1080p" \
  "content/sports_720p" \
  "content/sports_360p" \
  "ads/callaway_30s_1080p" \
  "ads/nike_15s_1080p" \
  "ads/bmw_30s_1080p" \
  "ads/taylormade_15s_1080p" \
  "ads/rolex_30s_1080p" \
  "manifests"; do
  echo "CMXS Media: $dir" | aws s3 cp - "s3://${BUCKET}/${dir}/.keep" \
    --content-type "text/plain" 2>/dev/null
done

# ── 6. Create CloudFront distribution ────────────────────────────────────────
echo ""
echo "▶ Creating CloudFront distribution..."

DISTRIBUTION_CONFIG="{
  \"CallerReference\": \"cmxs-prototype-$(date +%s)\",
  \"Comment\": \"CMXS Prototype Media CDN\",
  \"Origins\": {
    \"Quantity\": 1,
    \"Items\": [{
      \"Id\": \"S3-${BUCKET}\",
      \"DomainName\": \"${BUCKET}.s3.${REGION}.amazonaws.com\",
      \"S3OriginConfig\": { \"OriginAccessIdentity\": \"\" }
    }]
  },
  \"DefaultCacheBehavior\": {
    \"TargetOriginId\": \"S3-${BUCKET}\",
    \"ViewerProtocolPolicy\": \"redirect-to-https\",
    \"CachePolicyId\": \"658327ea-f89d-4fab-a63d-7e88639e58f6\",
    \"Compress\": true,
    \"AllowedMethods\": {
      \"Quantity\": 2,
      \"Items\": [\"GET\", \"HEAD\"],
      \"CachedMethods\": { \"Quantity\": 2, \"Items\": [\"GET\", \"HEAD\"] }
    }
  },
  \"CacheBehaviors\": {
    \"Quantity\": 1,
    \"Items\": [{
      \"PathPattern\": \"manifests/*\",
      \"TargetOriginId\": \"S3-${BUCKET}\",
      \"ViewerProtocolPolicy\": \"redirect-to-https\",
      \"CachePolicyId\": \"4135ea2d-6df8-44a3-9df3-4b5a84be39ad\",
      \"Compress\": false,
      \"AllowedMethods\": {
        \"Quantity\": 2,
        \"Items\": [\"GET\", \"HEAD\"],
        \"CachedMethods\": { \"Quantity\": 2, \"Items\": [\"GET\", \"HEAD\"] }
      }
    }]
  },
  \"Enabled\": true,
  \"HttpVersion\": \"http2and3\",
  \"IsIPV6Enabled\": true,
  \"PriceClass\": \"PriceClass_100\"
}"

CF_OUTPUT=$(aws cloudfront create-distribution \
  --distribution-config "$DISTRIBUTION_CONFIG" \
  --query '[Distribution.DomainName, Distribution.Id]' \
  --output text 2>/dev/null) || {
    echo "  ⚠️  CloudFront creation failed — may already exist or need permissions"
    echo "  Manual step: Create distribution at console.aws.amazon.com/cloudfront"
    CF_OUTPUT=""
  }

# ── 7. Print results ──────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo "  ✅ Setup Complete"
echo "═══════════════════════════════════════════════"
echo ""
echo "  S3 Bucket URL:"
echo "    https://${BUCKET}.s3.${REGION}.amazonaws.com"
echo ""
if [ -n "$CF_OUTPUT" ]; then
  CF_DOMAIN=$(echo "$CF_OUTPUT" | awk '{print $1}')
  CF_ID=$(echo "$CF_OUTPUT" | awk '{print $2}')
  echo "  CloudFront Domain : $CF_DOMAIN"
  echo "  CloudFront ID     : $CF_ID"
  echo ""
  echo "  ⚠️  IMPORTANT: Add to packages/api/.env:"
  echo "    CLOUDFRONT_DOMAIN=$CF_DOMAIN"
  echo "    CLOUDFRONT_ID=$CF_ID"
fi
echo ""
echo "  Next step: run  bash scripts/generate-test-hls.sh"
echo ""
