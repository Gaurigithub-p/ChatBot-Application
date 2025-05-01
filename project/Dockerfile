# Stage 1: Build the application with Node.js
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy project files
COPY . .

# Build the application
RUN npm run build

# Stage 2: Set up the production environment using Nginx
FROM nginx:alpine

# Copy built assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom nginx config if needed
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose the port Nginx is listening on (usually 80)
EXPOSE 80

# Start nginx in the foreground (properly serve static content)
CMD ["nginx", "-g", "daemon off;"]
