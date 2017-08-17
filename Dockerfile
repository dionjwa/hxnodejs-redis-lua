FROM haxe:3.4.2

####################
# Node.js/NPM
####################
# Dependencies
RUN apt-get update && \
	apt-get install -y build-essential g++ g++-multilib libgc-dev python && \
	curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
	apt-get -y install nodejs && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# install dependencies
COPY *.hxml /usr/src/app/
RUN haxelib git hxnodejs-redis https://github.com/proletariatgames/hxnodejs-redis.git
RUN haxelib install hxnodejs 4.0.9
RUN haxelib install promhx 1.1.0
RUN haxelib install promhx-unit-test 2.1.2
# RUN yes | haxelib install all

COPY package.json /usr/src/app/
RUN npm i
