all: dist/build/usrsbin-site/usrsbin-site gen

gen: dist/build/usrsbin-site/usrsbin-site
	dist/build/usrsbin-site/usrsbin-site build

dist/build/usrsbin-site/usrsbin-site: site.hs
	cabal build

preview: dist/build/usrsbin-site/usrsbin-site gen
	dist/build/usrsbin-site/usrsbin-site preview

clean:
	cabal clean

clean-site: dist/build/usrsbin-site/usrsbin-site
	dist/build/usrsbin-site/usrsbin-site clean
