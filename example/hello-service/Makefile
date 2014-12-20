?PHONY: build slug upload

# This is what your Continuous Delivery tool would do
build: slug upload

slug:
	sbt universal:packageZipTarball
	echo "SLUG=target/universal/hello-service-latest.tgz"

upload:
	s3cmd put target/universal/hello-service-latest.tgz s3://eam-scratch/
	s3cmd put .env s3://eam-scratch/hello-service.env
