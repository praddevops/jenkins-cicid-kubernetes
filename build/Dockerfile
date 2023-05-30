ARG ARCH=linux/arm/v7

FROM --platoform=$ARCH node:20-alpine3.16

RUN mkdir -p /home/node/app/node_modules && chown -R node:node /home/node/app

WORKDIR /home/node/app

COPY ./src/main/node-app/package*.json ./

USER node

RUN npm install

USER root

COPY ./src/main/node-app/ .

RUN chown -R node:node .

USER node

EXPOSE 8080

CMD [ "node", "app.js" ]
