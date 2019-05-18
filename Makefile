export APP_NAME := dummyruby
export PROJECT := astute-task-237715

export BRANCH := $(shell git rev-parse --abbrev-ref HEAD | sed -e 's/\//-/g')
export TS := $(shell git show -s --format=%ct)
export DATE_FORMAT := "%Y-%m-%dT%H-%M"
export DATE := $(shell date -u +$(DATE_FORMAT) -d@$(TS) 2>/dev/null || date -u -r $(TS) +$(DATE_FORMAT))
export REV := $(shell git rev-parse --short HEAD)
export TAG_NAME := "$(BRANCH)-$(DATE)-$(REV)"

build:
	docker build . -t $(APP_NAME):latest --build-arg TAG_NAME=${TAG_NAME}
	# docker tag $(APP_NAME):latest gcr.io/$(PROJECT)/$(APP_NAME):latest
	docker tag $(APP_NAME):latest weapp/$(APP_NAME):latest

push:
	# docker push gcr.io/$(PROJECT)/$(APP_NAME):latest
	docker push weapp/$(APP_NAME):latest

run:
	docker run -it -p8080:8080 --name $(APP_NAME) --rm $(APP_NAME):latest

yml:
	ruby tmpl.rb kube.yml

kube:
	ruby tmpl.rb kube.yml |tee /dev/stderr | kubectl apply -f -
	# kubectl apply -f kube.yml

services:
	kubectl get service
