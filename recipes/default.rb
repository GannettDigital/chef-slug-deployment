require 'uri'

include_recipe 'nginx'
include_recipe 'supervisor'

###############################################################################
## Extract the recipe cfg
###############################################################################
cfg = SlugDeployment.cfg(node)

def download(url, path)
  if url.start_with? "s3://" then
    execute "s3cmd get --force #{url} #{path}"
  else 
    remote_file path do
      source url
    end 
  end
end


###############################################################################
## Set up the service's user and service_root
###############################################################################
user cfg.owner do
  supports :manage_home => true
  home cfg.owner_home
end

directory cfg.slug_app_root do
  mode 0755
  owner owner
  recursive true
end


template cfg.start_script do
  source "run-service.erb"
  mode 0555
end



###############################################################################
## Download the env
###############################################################################
download(cfg.env_url, cfg.env_path)

###############################################################################
## Download and extract the slug
###############################################################################
download(cfg.slug_url, cfg.slug_path)
execute "tar xvzf #{cfg.slug_path}" do
  cwd cfg.slug_app_root
end



###############################################################################
## Configure Supervisor
###############################################################################
supervisor_service cfg.slug_name do
  action :enable
  autostart true
  user cfg.owner
  directory cfg.slug_app_root
  command cfg.command
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
