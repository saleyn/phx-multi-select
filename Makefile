all: deps assets/node_modules compile

deps:
	mix deps.get

compile: deps
	mix $@

clean:
	rm -fr _build

run: assets/node_modules
	iex -S mix phx.server

assets/node_modules:
	cd assets && npm install

shell:
	iex -S mix phx.server --no-start
