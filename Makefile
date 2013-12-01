all: dist/build/usrsbin-site/usrsbin-site gen

gen: dist/build/usrsbin-site/usrsbin-site
	dist/build/usrsbin-site/usrsbin-site build

dist/build/usrsbin-site/usrsbin-site:
	cabal build

preview: dist/build/usrsbin-site/usrsbin-site gen
	dist/build/usrsbin-site/usrsbin-site preview

clean:
	cabal clean
