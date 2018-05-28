SHELL=/bin/bash

export DOCKER_IMAGE     ?= test-image

.PHONY: build
build:
	docker-compose build


.PHONY: test
test:
	docker-compose up --abort-on-container-exit --exit-code-from=haxe


.PHONY: image
image: image
	docker build -t ${DOCKER_IMAGE} .


.PHONY: haxelib
haxelib:
	haxelib install --always build.hxml
	haxelib install --always test/travis.hxml
