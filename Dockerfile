FROM node:19-slim

WORKDIR /app

COPY data /app/data
COPY tools /app

RUN npm install

CMD /usr/local/bin/node /app/csv2gql.mjs ${DB_URI}
