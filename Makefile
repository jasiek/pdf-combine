test:
	docker run -it -v $(shell pwd):/usr/src/app pdf ruby combine_test.rb

