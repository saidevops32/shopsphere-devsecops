# Deliberately old/vulnerable base + root user. Use to watch Trivy and Hadolint FAIL the pipeline.
FROM node:14
RUN apt-get update && apt-get install -y curl
COPY . /app
CMD ["node", "/app/server.js"]
