FROM node:18-alpine

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create app directory
WORKDIR /directus

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Create uploads directory
RUN mkdir -p uploads

# Copy uploads if they exist
COPY uploads/ ./uploads/

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S directus -u 1001

# Change ownership of the app directory
RUN chown -R directus:nodejs /directus
USER directus

# Expose port
EXPOSE 8055

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8055/server/ping', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Start the application
ENTRYPOINT ["dumb-init", "--"]
CMD ["npx", "directus", "start"]
