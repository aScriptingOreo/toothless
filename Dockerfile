FROM oven/bun:latest as builder

WORKDIR /app

# Copy package files
COPY package.json bun.lockb ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy source code
COPY . .

# Build the static site
RUN bun run build

# Final stage - serve with vite preview
FROM oven/bun:latest

WORKDIR /app

# Copy package files
COPY package.json bun.lockb ./

# Install dependencies (production only)
RUN bun install --frozen-lockfile --production

# Copy built artifacts from builder
COPY --from=builder /app/build ./build

# Expose port
EXPOSE 5173

# Serve the static build
CMD ["bun", "run", "preview", "--host", "0.0.0.0"]
