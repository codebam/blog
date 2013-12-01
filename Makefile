all: dist/build/usrsbin-site/usrsbin-site gen

gen: dist/build/usrsbin-site/usrsbin-site
	dist/build/usrsbin-site/usrsbin-site build

dist/build/usrsbin-site/usrsbin-site: site.hs
	cabal build

preview: dist/build/usrsbin-site/usrsbin-site gen
	dist/build/usrsbin-site/usrsbin-site watch

clean:
	cabal clean

clean-site: dist/build/usrsbin-site/usrsbin-site
	dist/build/usrsbin-site/usrsbin-site clean

deploy: gen
	s3cmd sync -P _site/ s3://www.usrsb.in
