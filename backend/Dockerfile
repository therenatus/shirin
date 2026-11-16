# ---------- development: used by docker-compose.yml (hot reload) ----------
FROM node:20-alpine AS development

RUN apk add --no-cache openssl

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npx prisma generate || true

EXPOSE 3000

CMD ["npm", "run", "start:dev"]

# ---------- build: compile the API and the seed ----------
FROM node:20-alpine AS build

RUN apk add --no-cache openssl

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npx prisma generate && npm run build && npm prune --omit=dev

# ---------- production: used by docker-compose.prod.yml ----------
FROM node:20-alpine AS production

RUN apk add --no-cache openssl tini

ENV NODE_ENV=production
WORKDIR /app

COPY --from=build --chown=node:node /app/package*.json ./
COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist
COPY --from=build --chown=node:node /app/prisma ./prisma

USER node
EXPOSE 3000

# Apply migrations, ensure settings / first admin, start the API
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/prisma/seed.js && node dist/src/main.js"]
