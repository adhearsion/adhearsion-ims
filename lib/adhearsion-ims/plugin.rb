module Adhearsion
  module IMS
    class Plugin < Adhearsion::Plugin
      # Actions to perform when the plugin is loaded
      #
      init :adhearsion_ims do
        logger.info "adhearsion-ims has been loaded"
      end
  
      # Basic configuration for the plugin
      #
      config :adhearsion_ims do
        sbc_address nil,              :desc => "The Hostname or IP Address of the Session Border Controller (SBC) of the IMS [OPTIONAL]"
        cscf_address "192.168.0.2",   :desc => "The Hostname or IP Address of the Call Session Control Function (CSCF) of the IMS. Can not be nil.",
                                      :transform => Proc.new { |v| Adhearsion::IMS::Plugin.enforce_not_nil v }
        originating_ims_identity nil, :desc => "Originating IMS Identity for an Out of the Blue session. Can not be nil.",
                                      :transform => Proc.new { |v| Adhearsion::IMS::Plugin.enforce_not_nil v }
        uvp_address '192.168.0.3',    :desc => "The Hostname or IP Address of the Universal Voice Platform (UVP) of the IMS"
        exclude_routes [],            :desc => "An array of routes to exclude from the route header.",
                                      :transform => Proc.new { |v| Adhearsion::IMS::Plugin.enforce_array v }
      end
    
      # Defining a Rake task is easy
      # The following can be invoked with:
      #   rake plugin_demo:info
      #
      tasks do
        namespace :adhearsion_ims do
          desc "Prints the AdhearsionIMS::Plugin information"
          task :info do
            STDOUT.puts "adhearsion-ims plugin v. #{VERSION}"
            STDOUT.puts "Provides support for the IP Multimedia Subsystem (IMS) integration with PRISM & Rayo"
            STDOUT.puts "For more information please refer to http://en.wikipedia.org/wiki/IP_Multimedia_Subsystem."
          end
        end
      end
      
      private
      
      class << self
        def enforce_not_nil(v)
          raise ArgumentError if v.nil?
          v
        end
      end
    end
  end
end
