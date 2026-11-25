FROM node:24-bookworm-slim

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=4010

COPY package*.json ./

RUN npm ci --omit=dev

COPY --chown=node:node src ./src

USER node

EXPOSE 4010

CMD ["node", "src/index.js"]
