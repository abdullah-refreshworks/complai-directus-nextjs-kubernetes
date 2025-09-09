FROM directus/directus:latest

# Create uploads directory
RUN mkdir -p /directus/uploads

# Copy uploads if they exist
COPY uploads/ /directus/uploads/

# Expose port
EXPOSE 8055

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8055/server/ping', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"
