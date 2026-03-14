#!/bin/bash
set -e

# Build script for Espresso ML PostgreSQL custom image
# Usage: ./build-image.sh [tag] [registry]

# Default values
TAG=${1:-latest}
REGISTRY=${2:-ghcr.io/otnipid}
IMAGE_NAME="espresso-ai-db-postgres"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏗️  Building Espresso ML PostgreSQL image...${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check if schema files exist
if [ ! -d "charts/postgesql/schema" ]; then
    echo -e "${RED}❌ Schema directory not found: charts/postgesql/schema${NC}"
    exit 1
fi

# Count schema files
SCHEMA_FILES=$(find charts/postgesql/schema -name "*.sql" | wc -l)
echo -e "${YELLOW}📋 Found $SCHEMA_FILES schema files to include${NC}"

# Build the image
echo -e "${BLUE}🔨 Building image: $REGISTRY/$IMAGE_NAME:$TAG${NC}"
docker build \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    --cache-from "$REGISTRY/$IMAGE_NAME:latest" \
    --tag "$REGISTRY/$IMAGE_NAME:$TAG" \
    --tag "$REGISTRY/$IMAGE_NAME:latest" \
    .

echo -e "${GREEN}✅ Build completed successfully!${NC}"

# Show image details
echo -e "${BLUE}📊 Image details:${NC}"
docker images "$REGISTRY/$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# Test the image (optional)
if [ "$3" = "--test" ]; then
    echo -e "${YELLOW}🧪 Testing the image...${NC}"
    
    # Start a temporary container
    CONTAINER_NAME="espresso-ml-test-$(date +%s)"
    docker run -d \
        --name "$CONTAINER_NAME" \
        -e POSTGRES_PASSWORD=${CI_TEST_PASSWORD:-testpass} \
        -e POSTGRES_DB=testdb \
        -p 5433:5432 \
        "$REGISTRY/$IMAGE_NAME:$TAG"
    
    echo -e "${BLUE}⏳ Waiting for database to initialize...${NC}"
    sleep 10
    
    # Check if container is healthy
    if docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" | grep -q "$CONTAINER_NAME"; then
        echo -e "${GREEN}✅ Container is running successfully${NC}"
        
        # Test database connection
        if docker exec "$CONTAINER_NAME" pg_isready -U postgres; then
            echo -e "${GREEN}✅ Database is ready and accepting connections${NC}"
            
            # Check if tables were created
            TABLES=$(docker exec "$CONTAINER_NAME" psql -U postgres -d testdb -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('users', 'beans', 'shots')")
            if [ "$TABLES" -eq 3 ]; then
                echo -e "${GREEN}✅ Database schema initialized successfully ($TABLES key tables found)${NC}"
            else
                echo -e "${YELLOW}⚠️  Expected 3 key tables, found $TABLES${NC}"
            fi
        else
            echo -e "${RED}❌ Database is not ready${NC}"
        fi
    else
        echo -e "${RED}❌ Container failed to start${NC}"
    fi
    
    # Cleanup
    echo -e "${BLUE}🧹 Cleaning up test container...${NC}"
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

echo -e "${GREEN}🎉 Build process completed!${NC}"
echo -e "${BLUE}📝 To push to registry:${NC}"
echo -e "   docker push $REGISTRY/$IMAGE_NAME:$TAG"
echo -e "   docker push $REGISTRY/$IMAGE_NAME:latest"
echo ""
echo -e "${BLUE}🚀 To run locally:${NC}"
echo -e "   docker run -d --name espresso-postgres -e POSTGRES_PASSWORD=\${POSTGRES_PASSWORD:-yourpassword} -p 5432:5432 $REGISTRY/$IMAGE_NAME:$TAG"
