# slug-deployment Cookbook

The goal of this project is to provide a very general and simple
recipe for deploying [12-factor](http://12factor.net/) applications
using cloud servers and a continuous delivery pipeline.

It has support for both [.env](https://github.com/bkeepers/dotenv)
files and a [Procfile](https://devcenter.heroku.com/articles/procfile).

It should be very easy to deploy applications already built on Heroku.

https://github.com/ericmoritz/chef-slug-deployment

## What is a slug?

A slug is a `.tgz` file that contains the root directory of your
service.

It contains all the necessary libraries to run your application.  This
could be a `sbt universal:packageZipTarball` tgz file or a Python
`virtualenv` or a `node.js` root.

## Design

```
   nginx -> supervisord -> app processes
```

This recipe will read the Procfile at the root of your slug `.tgz` and
generate a [supervisord] conf file for the processes defined in the
Procfile.

## Requirements

This cookbook will install the following packages:

  - nginx
  - supervisor

If you want to use `s3://` URLs, `s3cmd` needs to be installed.

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['slug-deployment]['name']</tt></td>
    <td>String</td>
    <td>Name of the app</td>
    <td><tt></tt></td>
  </tr>
  <tr>
    <td><tt>['slug-deployment']['slug_url']</tt></td>
    <td>String</td>
    <td>URL to the slug .tgz file, http://, https://, s3://</td>
    <td><tt></tt></td>
  </tr>
  <tr>
    <td><tt>['slug-deployment']['env_url]</tt></td>
    <td>Boolean</td>
    <td>An ERB template for the environment URL, http://, https://, s3://</td>
    <td><tt></tt></td>
  </tr>
  <tr>
    <td><tt>['slug-deployment'']['chdir']</tt></td>
    <td>String</td>
    <td>before starting the service chdir to the directory relative to the slug root</td>
    <td><tt></tt></td>
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


## Example: Hello Service

We have provided a "Hello, World!" service in `example/hello-service`
and a sample Vagrant configuration in
`example/hello-service-deployment`.

`hello-service` is a simple Scala web service that greets you
differently based on the environment it is deployed to.

License and Authors
-------------------

Authors: Eric Moritz (http://github.com/ericmoritz)

