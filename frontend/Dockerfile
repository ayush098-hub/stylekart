FROM node:25-alpine3.22 AS builder
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build
FROM nginx:latest
WORKDIR /usr/share/nginx/html
COPY --from=builder /app/build/ .
