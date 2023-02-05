all: deps compile

deps:
	mix deps.get

compile: deps
	mix $@

clean:
	rm -fr _build

distclean: clean
	$(MAKE) -C example $@
