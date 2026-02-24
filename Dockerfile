# ACC RTV Tour Tester - Container Image
FROM oven/bun:alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json bun.lock* ./

# Install dependencies
RUN bun install --production

# Copy application files
COPY proxy.js index.html ./

# Expose port 3110 (proxy + static files)
EXPOSE 3110

# Start the application
CMD ["bun", "run", "proxy.js"]
