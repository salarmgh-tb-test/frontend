FROM node:25.2.1-alpine3.22 AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies (including devDependencies for Vite build)
RUN npm ci

# Build arguments
ARG NODE_ENV=production
ARG VITE_API_URL=http://localhost:80

# Set environment variables for build (used during Vite build)
ENV NODE_ENV=${NODE_ENV} \
    VITE_API_URL=${VITE_API_URL}

# Copy source code
COPY . .

# Build the application
RUN npm run build

FROM nginx:1.29.4-alpine3.23 AS production

# Create nginx cache directories with correct permissions
RUN mkdir -p /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp \
    /var/log/nginx \
    /var/run/nginx && \
    chown -R nginx:nginx /var/cache/nginx /var/log/nginx /var/run/nginx

USER nginx

WORKDIR /usr/share/nginx/html

# Copy built assets from builder stage
COPY --from=builder --chown=nginx:nginx /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

