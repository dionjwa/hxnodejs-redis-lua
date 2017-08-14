FROM haxe:3.4.2

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# install dependencies
COPY *.hxml /usr/src/app/
RUN yes | haxelib install all

# compile the project
# COPY ./src /usr/src/app/src
# ARG BUILD_HXML=build.hxml
# RUN haxe $BUILD_HXML