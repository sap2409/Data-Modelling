FROM node:22-alpine AS base

WORKDIR /app

COPY apps/web/package*.json ./
RUN npm ci

COPY apps/web ./

ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
