test:
	rm -rf out
	mkdir out
	python ../../../files/render-supervisor-group.py out
	cmp --silent test-app.conf out/test-app.conf
