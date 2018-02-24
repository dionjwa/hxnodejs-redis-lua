FROM dionjwa/haxe-watch
MAINTAINER dion@transition9.com

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# install dependencies
COPY *.hxml /usr/src/app/
RUN yes | haxelib install all
RUN haxelib git hxnodejs-redis https://github.com/proletariatgames/hxnodejs-redis.git

COPY package.json /usr/src/app/
RUN npm i
