FROM node:20-alpine AS development

RUN apk add --no-cache openssl

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npx prisma generate || true

EXPOSE 3000

CMD ["npm", "run", "start:dev"]
