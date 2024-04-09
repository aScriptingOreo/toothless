FROM node:20-buster

WORKDIR /app

COPY package*.json ./

RUN npm i -g bun ts-node typescript

RUN bun i

COPY . .

EXPOSE 3000

ARG PORT
CMD [ "bun", "run", "start"	 ]