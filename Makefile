.PHONY: build typecheck test docs links sizes check clean

build:
	idris2 --build mf2.ipkg

typecheck:
	idris2 --typecheck mf2.ipkg

test: build
	IDRIS2_PATH="$(CURDIR)/src" idris2 --build mf2-tests.ipkg
	./build/exec/mf2-tests

docs:
	idris2 --mkdoc mf2.ipkg

links:
	bash scripts/check-doc-links.sh

sizes:
	bash scripts/check-file-sizes.sh

check: typecheck test docs links sizes

clean:
	idris2 --clean mf2.ipkg
	idris2 --clean mf2-tests.ipkg
