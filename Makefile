all: compile

compile:
	mix $@

clean:
	rm -fr _build

run:
	iex -S mix phx.server

shell:
	iex -S mix phx.server --no-start
