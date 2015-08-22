gen:
	usrsbin-site build

preview:
	usrsbin-site watch

build: 
	stack build --copy-bins

deploy:
	s3cmd sync -P _site/ s3://www.usrsb.in
