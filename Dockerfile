FROM node:25.2.1-alpine3.22 AS builder

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci

ARG NODE_ENV=production
ARG VITE_API_URL=http://localhost:80

ENV NODE_ENV=${NODE_ENV} \
    VITE_API_URL=${VITE_API_URL}

COPY . .

RUN npm run build

FROM nginx:1.29.4-alpine3.23 AS production

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

COPY --from=builder --chown=nginx:nginx /app/dist /usr/share/nginx/html

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]