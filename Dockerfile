## Multi-stage build: build with Node, serve static output with nginx (small runtime)

#############################
# Builder: use Node (alpine) to build the static site
#############################
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies (including dev deps needed for build)
COPY package.json package-lock.json* ./
RUN npm ci --silent || npm install --silent

# Copy source and build
COPY . .
RUN npm run build

#############################
# Final: lightweight nginx to serve the built static files
#############################
FROM nginx:alpine

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy built site from builder
COPY --from=builder /app/build /usr/share/nginx/html

# Expose standard HTTP port
EXPOSE 80

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
