test:
	pip install pystache==0.5.4
	@make -C tests/render-supervisor-group/fixtures test
