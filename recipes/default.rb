require 'uri'
chef_gem 'foreman'
require 'foreman/procfile'
require 'dotenv'

include_recipe 'nginx'
include_recipe 'supervisor'

python_pip "pystache==0.5.4"

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
## Extract the recipe cfg
###############################################################################
cfg = SlugDeployment.cfg(node)

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

# dump the config as a manifest
template "/root/environment.txt" do
  source "environment.txt.erb"
  mode 0644
  variables :cfg => cfg
end

###############################################################################
## Render the slug-manifest.json file
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

# render the get-config.sh script
template "/root/#{cfg.app_name}-get-config.sh" do
  source "get-config.sh.erb"
  mode 0755
  variables :cfg => cfg
end


## use the render command to create the new group
execute "/root/#{cfg.app_name}-get-config.sh" do
  cwd cfg.cwd
end

## restart supervisor to get the new command
service "supervisor" do
  action [:restart]
end

## install the get-config.sh cron job to monitor and update the service
## when the env changes
cron "get-config.sh" do
  minute '*/5'
  command "/root/#{cfg.app_name}-get-config.sh 2>&1 > /var/log/#{cfg.app_name}-get-config.sh.log"
end

###############################################################################
## Setup nginx to proxy to the backend service
###############################################################################
# detect if there is a web worker
ruby_block "config" do
  block do
    Foreman::Procfile.new("#{cfg.cwd}/Procfile").entries do |name, command| 
      # web is always on web, everything else is an offset of 5000
      if name == "web" then
        node.set['slug-deployment']['web_worker?'] = true
      end
    end
  end
end


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
