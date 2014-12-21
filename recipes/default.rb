require 'uri'
chef_gem 'foreman'
require 'foreman/procfile'
require 'dotenv'

include_recipe 'nginx'
include_recipe 'supervisor'

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
user cfg.user do
  supports :manage_home => true
  home cfg.home
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
ruby_block "config" do
  block do
    node.set['env'] = Dotenv::Environment.new("#{cfg.cwd}/.env")
    port = 5000
    procs = []
    Foreman::Procfile.new("#{cfg.cwd}/Procfile").entries do |name, command| 
      procs.push({:name => name, :command => command, :port => port})
      port = port + 1
    end
    node.set['procs'] = procs
  end
end



template "/etc/supervisor.d/#{cfg.app_name}.conf" do
  source "supervisor-group.conf.erb"
  mode 0644
  variables :cfg => cfg
end

service "supervisor" do
  action [:restart]
end

###############################################################################
## Setup nginx to proxy to the backend service
###############################################################################
template "/etc/nginx/conf.d/default.conf" do
  source "slug-nginx.conf.erb"
  mode 0644
end

file "/etc/nginx/sites-enabled/*" do
  action :delete
end

service "nginx" do
  action [:restart]
end
