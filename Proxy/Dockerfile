FROM node:20-slim

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --omit=dev

# Copy source
COPY server.js ./

# Expose port
EXPOSE 8080

# Start server
CMD ["node", "server.js"]
