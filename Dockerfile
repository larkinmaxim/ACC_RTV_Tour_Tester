# ACC RTV Tour Tester - Container Image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm install --production

# Copy application files
COPY proxy.js index.html ./

# Expose port 3110 (proxy + static files)
EXPOSE 3110

# Start the application
CMD ["node", "proxy.js"]
