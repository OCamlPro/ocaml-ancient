FLAGS?=

all: build

watch:
	dune build $(FLAGS) -w @check

top:
	dune utop

build:
	dune build $(FLAGS)

test:
	dune build $(FLAGS) @runtest

clean:
	dune clean

.PHONY: all build test clean
