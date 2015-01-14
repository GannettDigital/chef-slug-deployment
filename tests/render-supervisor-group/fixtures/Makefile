test:
	rm -rf out
	mkdir out
	python ../../../templates/render-supervisor-group.py out
	cmp --silent test-app.conf out/test-app.conf
