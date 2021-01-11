test:
	docker run -it -v $(shell pwd):/usr/src/app pdf ruby combine_test.rb

run:
	docker run -it -p5000:5000 -v $(shell pwd):/usr/src/app pdf
