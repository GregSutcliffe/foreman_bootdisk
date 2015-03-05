require 'uri'

module ForemanBootdisk
  class Renderer
    include ::Foreman::Renderer
    include Rails.application.routes.url_helpers

    def generic_template_render(host=nil)
      if (Gem::Version.new(SETTINGS[:version].notag) < Gem::Version.new('1.5')) && Setting[:safemode_render]
        raise(::Foreman::Exception.new(N_('Bootdisk is not supported with safemode rendering, please disable safemode_render under Adminster>Settings')))
      end

      tmpl = ConfigTemplate.find_by_name(Setting[:bootdisk_generic_host_template]) || raise(::Foreman::Exception.new(N_('Unable to find template specified by %s setting'), 'bootdisk_generic_host_template'))

      if host.present?
        # supplying a host is used to render a subnet-level generic template, containing the template proxy
        # for that subnet. Rendering this requires a host with a token, so use the same restriction
        raise ::Foreman::Exception.new(N_('Host is not in build mode, so the template cannot be rendered')) unless host.build?
        @host = host
      else
        @host = Struct.new(:token, :subnet).new(nil,nil)
      end
      rtmpl = unattended_render(tmpl.template)
      # remove the token from subnet-level generation, since this is meant to be generic
      rtmpl.gsub!(/(?<=iPXE\?)token\S*(?=mac=)/,'') if host.present?
      rtmpl
    end

    def bootdisk_chain_url(action = 'iPXE')
      u = URI.parse(foreman_url(action))
      u.query = "#{u.query}&mac="
      u.fragment = nil
      u.to_s
    end
  end
end
