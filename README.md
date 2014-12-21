# slug-deployment Cookbook

This recipe implements deployment of a
[12-factor](http://12factor.net/) application.  It is inspired by the
Heroku and applications written for Heroku should be easy to deploy
using this recipe.

It is purposely designed to be a simple design that can be integrated
easily with cloud scaling environments and continuous delivery systems.

https://github.com/ericmoritz/chef-slug-deployment

## Requirements

This cookbook will install the following packages:

  - nginx
  - supervisor

If you want to use s3:// URLs, `s3cmd` needs to be installed and
configured before running this recipe.

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

## Usage

This recipe is intended to be use as a dependancy of a more specific
recipe.  Your service repipe will install prerequisites for running
your service.  For instance if you have written a Python app, your
service deployment recipe will install `python` and then
`slug-deployment`.

The slug and env files are built and uploaded by your continuous
delivery tool.  Once those artifacts are uploaded, this recipe can
be executed on new node.

### What is a slug?

A slug is a .tgz file that contains the root directory of your
service.  It contains all the necessary libraries to run your
application.  This could be a `sbt universal:packageZipTarball` tgz
file or a Python `virtualenv` for instance.

### What is a env file?

An env file is a file that is in the following format:

```
export S3_BUCKET=YOURS3BUCKET
export SECRET_KEY=YOURSECRETKEYGOESHERE
```

This env file sets up the environment for processes started by this
recipe.

## Example: Hello Service

We have provided a "Hello, World!" service in `example/hello-service`.
It is a simple Scala web service that greets you differently based on
the environment it is deployed to.


### Build 

First the slug needs to be built and deployed to a URL accessable
by the machine being built by Chef.  This URL will be your 
`['slug-deployment']['slug_url']` attribute.

Let's build the `hello-service`.

```
$ s3cmd --configure # skip if you've done this
$ cd example/hello-service
$ S3_BUCKET=<<your S3 bucket>> make slug upload
```

License and Authors
-------------------

Authors: Eric Moritz (http://github.com/ericmoritz)

