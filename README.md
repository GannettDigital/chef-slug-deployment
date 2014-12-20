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
    <td>URL to the env file, http://, https://, s3://</td>
    <td><tt></tt></td>
  </tr>
  <tr>
    <td><tt>['slug-deployment'']['command']</tt></td>
    <td>String</td>
    <td>Command to start the service</td>
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


License and Authors
-------------------

Authors: Eric Moritz (http://github.com/ericmoritz)

