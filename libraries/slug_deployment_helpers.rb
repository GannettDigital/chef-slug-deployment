require 'uri'
require 'ostruct'
require 'erb'

module SlugDeployment
  def SlugDeployment.cfg(node)
    raise "Missing name" unless node['slug-deployment']['name']
    raise "Missing slug_url" unless node['slug-deployment']['slug_url']
    raise "Missing env_url" unless node['slug-deployment']['env_url']
    raise "Missing command" unless node['slug-deployment']['command']

    cfg = OpenStruct.new
    cfg.slug_name = node['slug-deployment']['name']

    cfg.slug_url = node['slug-deployment']['slug_url']

    # Render the env_url as a ERB template. In good 12-factor fashion
    # the configuration is the only thing that changes between environment
    # and environment for the app
    context = OpenStruct.new(node: node)
    cfg.env_url = ERB.new(node['slug-deployment']['env_url']).result(context.instance_eval { binding })

    cfg.slug_root = "/opt/#{cfg.slug_name}"
    cfg.slug_app_root = "#{cfg.slug_root}/app"

    cfg.slug_filename = File.basename(URI.parse(cfg.slug_url).path)
    cfg.slug_path = "#{cfg.slug_root}/#{cfg.slug_filename}"
    cfg.env_path = "#{cfg.slug_app_root}/.env"

    cfg.owner = cfg.slug_name
    cfg.owner_home = "/home/#{cfg.owner}"

    cfg.start_script = "#{cfg.slug_root}/run-service"
    cfg.command = "#{cfg.start_script} #{node['slug-deployment']['command']}"

    return cfg
  end

end
