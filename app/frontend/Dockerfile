# Static SPA served by unprivileged NGINX (swap in a React build stage later: node build -> COPY dist)
FROM nginxinc/nginx-unprivileged:1.27-alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY src /usr/share/nginx/html
USER 10001
EXPOSE 8080
