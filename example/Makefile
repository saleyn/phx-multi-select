all: deps assets/node_modules priv/static/assets/app.js compile

deps:
	mix deps.get

compile: deps
	mix $@

clean:
	rm -fr _build assets/node_modules priv/static/assets/app*

run: assets/node_modules
	iex -S mix phx.server

assets/node_modules:
	cd assets && npm install

priv/static/assets/app.js:
	mix assets.deploy

shell:
	iex -S mix phx.server --no-start

docker-build:
	docker build -t multi-select .

docker-run:
	docker run -ti -w '/app' --env SECRET_KEY_BASE=$(shell mix phx.gen.secret) --entrypoint=/bin/sh multi-select --login

docker-prune:
	docker rmi $(shell docker images --filter "dangling=true" -q --no-trunc) --force
	docker rmi multi-select
