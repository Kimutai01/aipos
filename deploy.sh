#!/bin/bash
set -e

echo "🚀 Starting deployment..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables if .env.prod exists
if [ -f .env.prod ]; then
  echo -e "${BLUE}📝 Loading environment variables from .env.prod...${NC}"
  source .env.prod
else
  echo -e "${YELLOW}⚠️  Warning: .env.prod not found${NC}"
  echo -e "${YELLOW}   Create .env.prod from .env.prod.example and set your variables${NC}"
  echo -e "${YELLOW}   Or export them manually before running this script${NC}"
fi

# Export required environment variables
export MIX_ENV=prod
export PHX_SERVER=true

# Verify critical environment variables
echo -e "${BLUE}🔍 Checking environment variables...${NC}"
if [ -z "$DATABASE_URL" ]; then
  echo -e "${RED}❌ DATABASE_URL is not set${NC}"
  echo "   Export it with: export DATABASE_URL='ecto://user:pass@localhost/aipos_prod'"
  exit 1
fi

if [ -z "$SECRET_KEY_BASE" ]; then
  echo -e "${RED}❌ SECRET_KEY_BASE is not set${NC}"
  echo "   Generate one with: mix phx.gen.secret"
  echo "   Then export it with: export SECRET_KEY_BASE='your-generated-secret'"
  exit 1
fi

echo -e "${GREEN}✓ Environment variables OK${NC}"

# Get dependencies
echo -e "${BLUE}📦 Getting dependencies...${NC}"
mix deps.get --only prod

# Compile the application
echo -e "${BLUE}🔨 Compiling application...${NC}"
MIX_ENV=prod mix compile

# Build and digest assets
echo -e "${BLUE}🎨 Building and digesting assets...${NC}"
MIX_ENV=prod mix assets.deploy

# Run migrations
echo -e "${BLUE}🗄️  Running database migrations...${NC}"
MIX_ENV=prod mix ecto.migrate

echo -e "${GREEN}✅ Deployment complete!${NC}"
echo -e "${BLUE}📌 Next steps:${NC}"
echo "   1. Restart your Phoenix application"
echo "   2. Check that priv/static/cache_manifest.json exists"
echo ""
echo -e "${BLUE}To restart (choose one):${NC}"
echo "   • systemctl: sudo systemctl restart aipos"
echo "   • manual: pkill -f 'beam.*aipos' && MIX_ENV=prod elixir --erl '-detached' -S mix phx.server"
