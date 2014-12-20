?PHONY: build slug upload

# This is what your Continuous Delivery tool would do
build: slug upload

slug:
	# First build our slug, this is easy with sbt, it is a universal tgz file
	sbt universal:packageZipTarball
	# Echo the SLUG's path for CI tools to record the location
	echo "SLUG=`pwd`/target/universal/hello-service-latest.tgz"

upload:
	# Upload our slug to S3
	s3cmd put target/universal/hello-service-latest.tgz s3://${S3_BUCKET}/hello-service/

	# Upload our environments to S3
	s3cmd put --recursive environments s3://${S3_BUCKET}/hello-service/
