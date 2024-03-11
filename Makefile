all: deps compile

deps:
	mix deps.get

compile: deps
	mix $@

clean:
	rm -fr _build

outdated:
	mix hex.$@

distclean: clean
	$(MAKE) -C example $@
