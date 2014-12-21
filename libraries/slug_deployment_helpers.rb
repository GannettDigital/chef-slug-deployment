require 'uri'
require 'ostruct'
require 'erb'

module SlugDeployment
  def SlugDeployment.cfg(node)
    raise "Missing name" unless node['slug-deployment']['name']
    raise "Missing slug_url" unless node['slug-deployment']['slug_url']
    raise "Missing env_url" unless node['slug-deployment']['env_url']

    cfg = OpenStruct.new

    ## App config
    cfg.app_name = node['slug-deployment']['name']
    cfg.app_root = "/opt/#{cfg.app_name}"

    ## User config
    cfg.user = cfg.app_name
    cfg.home = "/home/#{cfg.user}"


    ## Command config
    cfg.command = "shoreman.sh"
    cfg.cwd = if node['slug-deployment']['chdir'] then 
                      "#{cfg.app_root}/#{node['slug-deployment']['chdir']}"
                    else
                      cfg.app_root
                    end

    ## Slug config
    cfg.slug_url = node['slug-deployment']['slug_url']
    cfg.slug_filename = File.basename(URI.parse(cfg.slug_url).path)
    cfg.slug_path = "#{cfg.app_root}/#{cfg.slug_filename}"


    ## Env Config
    # Render the env_url as a ERB template. In good 12-factor fashion
    # the configuration is the only thing that changes between environment
    # and environment for the app
    context = OpenStruct.new(node: node)
    cfg.env_url = ERB.new(node['slug-deployment']['env_url']).result(context.instance_eval { binding })
    cfg.env_path = "#{cfg.cwd}/.env"

    return cfg
  end

end
