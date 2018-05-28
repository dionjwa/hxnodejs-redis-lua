FROM dionjwa/haxe-watch:v0.15.0
MAINTAINER dion@transition9.com

WORKDIR /app
# install dependencies: npm
COPY ./package.json /app/package.json
COPY ./package-lock.json /app/package-lock.json
RUN npm i

# install dependencies: haxe
COPY build.hxml /app/build.hxml
COPY test/travis.hxml /app/test/travis.hxml
RUN haxelib install --always build.hxml
RUN haxelib install --always test/travis.hxml

COPY ./src /app/src
COPY ./test /app/test
