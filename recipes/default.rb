require 'uri'
chef_gem 'foreman'
require 'foreman/procfile'
require 'dotenv'

include_recipe 'nginx'
include_recipe 'supervisor'

python_pip "pystache==0.5.4"

###############################################################################
## Extract the recipe cfg
###############################################################################
cfg = SlugDeployment.cfg(node)

def download(url, path, user)
  if url.start_with? "s3://" then
    execute "s3cmd get --force #{url} #{path}" do

    end
  else 
    remote_file path do
      source url
    end 
  end
end


###############################################################################
## Set up the service's user and service_root
###############################################################################
if cfg.user != "nginx" then
  user cfg.user do
    supports :manage_home => true
    home cfg.home
  end
end


directory cfg.app_root do
  mode 0755
  owner cfg.user
  recursive true
end


###############################################################################
## Download and extract the slug
###############################################################################
download(cfg.slug_url, cfg.slug_path, cfg.user)
execute "tar xvzf #{cfg.slug_path}" do
  cwd cfg.app_root
  user cfg.user
end

###############################################################################
## Download the env
###############################################################################
download(cfg.env_url, cfg.env_path, cfg.user)




###############################################################################
## Configure Supervisor
###############################################################################
# dump the config as a manifest
ruby_block "slug-manifest.json" do
  block do
    
    File.write("#{cfg.cwd}/.slug-manifest.json", 
               JSON.generate({
                               "app_name" => cfg.app_name,
                               "user" => cfg.user,
                               "env" => node['slug-deployment']['env'],
                               "cwd" => cfg.cwd
                             }))
  end
end


# put the supervisor group command to /usr/local/bin
cookbook_file "/usr/local/bin/render-supervisor-group.py" do
  source "render-supervisor-group.py"
  mode 0755
end

## use the render command to create the new group
execute "/usr/local/bin/render-supervisor-group.py /etc/supervisor.d/" do
  cwd cfg.cwd
end

## restart supervisor to get the new command
service "supervisor" do
  action [:restart]
end

###############################################################################
## Setup nginx to proxy to the backend service
###############################################################################
template "/etc/nginx/conf.d/default.conf" do
  source "slug-nginx.conf.erb"
  mode 0644
  variables :cfg => cfg
end

file "/etc/nginx/sites-enabled/*" do
  action :delete
end

service "nginx" do
  action [:restart]
end
