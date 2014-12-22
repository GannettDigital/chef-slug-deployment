# slug-deployment Cookbook

The goal of this project is to provide a very general and simple
recipe for deploying [12-factor](http://12factor.net/) applications
using cloud servers and a continuous delivery pipeline.

It has support for both [.env](https://github.com/bkeepers/dotenv)
files and a [Procfile](https://devcenter.heroku.com/articles/procfile).

It should be very easy to deploy applications already built on Heroku.

This recipe is intended to be part of a bigger continuous delivery
pipeline and auto-scalable cloud based solution.  A typical continuous
delivery pipeline could be as follows:

1. Build Phase
  1. Create a build VM
  2. Build and unit-test slug
  3. Upload Slug
2. Create a fresh stage VM
  1. Execute a chef role using `recipe[slug-deployment]` using the
     `stage` chef environment.
  2. Create an image of stage VM
  3. Deploy image to a stage cluster
  4. Execute acceptance tests against stage cluster
3. Create a fresh prod VM
  1. Execute a chef role using `recipe[slug-deployment]` using the
     `prod` chef environment.
  2. Create an image of prod VM
  3. Deploy image to a new prod cluster
  4. Execute availability tests against the prod cluster
  5. Replace old prod cluster with new prod cluster.

This recipe is model after the
[build, release, run](http://12factor.net/build-release-run) of a 12
factor application.  In short, a release is when the configuration
(the .env files) is combined with a build (the slug).

The .env files and the slug are dependencies of the build.  Whenever
there is a code change, this triggers a new build of a slug and
likewise whenever the .env files are changed, this triggers a new
release.

![12 Factor CD Pipeline](https://raw.githubusercontent.com/ericmoritz/chef-slug-deployment/master/docs/static/12_factor_cd.png)

### Design

This recipe will read the Procfile at the root of your slug `.tgz` and
generate a [supervisord](http://supervisord.org/) config for the
processes defined in the Procfile.

Your web service needs to binds to `127.0.0.1:$PORT`.  Nginx forwards
traffic from port 80 to your web service.

We use Nginx because your application runs under its own user and in
its own root to protect the system from application faults and
exploits.

Nginx will also allow us to efficiently serve static content when that
feature is implemented.

## What is a slug?

A slug is a `.tgz` file that contains the root directory of your
service. It contains all the necessary libraries to run your application.

Examples of possible slugs could be:

 * a tgz with a Python `virtualenv`
 * a `sbt universal:packageZipTarball` 
 * a node.js project root, with package installed in `node_packages`

## Procfile?

The [Procfile](https://devcenter.heroku.com/articles/procfile) is
placed in the root of the `.tgz` file and is used to configure
[supervisord](http://supervisord.org/).

```
web: gunicorn hellodjango.wsgi --log-file -
worker: celery worker --app=tasks.app
```

For instance the Procfile listed above will launch two processes, the
first is a `gunicorn` web service running on `127.0.0.1:$PORT`.

The second is the [Celery](http://www.celeryproject.org/) distributed
task queue system running in a separate process.

## dotenv file

The `.env` file you provide defines the [environment variables](http://12factor.net/config) that
configure your application. 

These variables provide configuration for the
[backing services](http://12factor.net/backing-services) for a
particular deployment.

For instance, your application may require a `redis` backing service:

```
REDIS_URL=redis://192.168.1.13:10041
```

This configuration is integrated like so:

```
import os
app.conf.update(BROKER_URL=os.environ['REDIS_URL'],
                CELERY_RESULT_BACKEND=os.environ['REDIS_URL'])
```

## Logging

In true [12 Factor](http://12factor.net/logs) fashion, app logs are
treated as an event stream.  This stream is simply sent to `syslog`.

You can configure your system to forward these events to a log
aggregator of your choice.

## Usage

### Requirements

If you want to use `s3://` URLs, `s3cmd` needs to be installed.

### Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><tt>['slug-deployment]['name']</tt></td>
    <td>String</td>
    <td>Name of the app</td>
  </tr>
  <tr>
    <td><tt>['slug-deployment']['slug_url']</tt></td>
    <td>String</td>
    <td>URL to the slug .tgz file, http://, https://, s3://</td>
  </tr>
  <tr>
    <td><tt>['slug-deployment']['env_url]</tt></td>
    <td>Boolean</td>
    <td>An ERB template for the environment URL, http://, https://, s3://</td>
  </tr>
  <tr>
    <td><tt>['slug-deployment'']['chdir']</tt></td>
    <td>String</td>
    <td>before starting the service `cd` to the directory relative to the slug root</td>
  </tr>
  <tr>
    <td><tt>['slug-deployment'']['static']</tt></td>
    <td>{url_path(): {'alias': str()[, 'expires': str()]}</td>
    <td>Maps a slug dir to a url path with an optional [expires](http://nginx.org/en/docs/http/ngx_http_headers_module.html#expires) header </td>
  </tr>

  <tr>
    <td><tt>['slug-deployment'']['env']</tt></td>
    <td>{str(): str()}</td>
    <td>Provide global environments variables. Useful for setting a global env per role or chef environment</td>
  </tr>

</table>

A note about the `env_url`.  The `env_url` is a ERB template string
that has access to the chef `node` variable.  This gives you access to
values such as `node.chef_environment` as well as any attributes
defined by your chef roles and chef environment.

You can use the template to generate a environment specific URL such as:

```
s3://eam-scratch/hello-service/environments/<%= node.chef_environment %>.env
```

### Example: Hello Service

We have provided a "Hello, World!" service in `example/hello-service`
and a sample Vagrant configuration in
`example/hello-service-deployment`.

`hello-service` is a simple Scala web service that greets you
differently based on the environment it is deployed to.

## License and Authors

Authors: Eric Moritz (http://github.com/ericmoritz)
https://github.com/ericmoritz/chef-slug-deployment

