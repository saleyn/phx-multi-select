all: deps compile

deps:
	mix deps.get

compile: deps
	mix $@

clean:
	rm -fr _build
