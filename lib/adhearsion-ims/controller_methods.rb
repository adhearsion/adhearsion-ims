module Adhearsion
  module IMS
    module CallControllerMethods
      ##
      # Creates an IMS dial string as a B2BUA or an Out of the Blue
      #
      # @overload initialize(params)
      #   @param [Required, Symbol] :b2bua or :out_of_the_blue
      #   @param [Optional, Hash] :from
      # @overload ims_dial_string(params, &block)
      #   @param [Required, Symbol] :b2bua or :out_of_the_blue
      #   @param [Required, Hash] :from the tel uri the call will be placed on behalf of
      #   @param [Required, Hash] :to the tel or SIP uri of the destination for the call
      # @return [String] the dial string
      # @return [Hash] dial options generated
      def generate_ims_options(type, options={})
        validate_options type, options
  
        return { :sip_uri => build_to(options), 
                 :options => { :from    => build_from(options),
                               :headers => generate_isc_headers(type) }
               }
      end
  
      ##
      # Creates the headers required for IMS B2BUA or Out of the Blue dialing
      #
      # @param [Symbol] type should be :b2bua or :out_of_the_blue
      # @return [Hash] header generated for the IMS
      def generate_isc_headers(type)
        headers={}
  
        case type
        when :b2bua
          headers[:route] = process_b2bua_route_headers(call.variables[:route])
          headers.merge! call.variables.select { |k,v| k =~ /^P/i }
        when :out_of_the_blue
          if Adhearsion::IMS::Plugin.config[:sbc_address]
            headers[:route] = config[:sbc_address] + delimitter + config[:cscf_address]
          else
            headers[:route] = config[:cscf_address]
          end
  
          headers[:p_charging_vector] = "icid-value=#{uuid};orig-ioi=#{config[:originating_ims_identity]}"
        end
  
        headers
      end
  
      private
  
      ##
      # Creates the route header based on a ||| list when multiple routes, also adding the SBC address if
      # required
      #
      # @param [String] route header
      # @return [String] the routes properly constructed
      def process_b2bua_route_headers(route)
        if route.match(/\|\|\|/)
          routes = remove_nodes(call.variables[:route].split('|||'))
          routes.unshift Adhearsion::IMS::Plugin.config[:sbc_address] if Adhearsion::IMS::Plugin.config[:sbc_address]
          new_route = routes.join('|||')
        else
          if Adhearsion::IMS::Plugin.config[:sbc_address]
            new_route = Adhearsion::IMS::Plugin.config[:sbc_address] + '|||' + route
          else
            new_route = route
          end
        end
  
        new_route
      end
      
      ##
      # Removes any nodes from the routes as specified in the configuration
      # 
      # @param [Array] route headers
      # @return [Array] the routes with any nodes removed
      def remove_nodes(routes)
        Adhearsion::IMS::Plugin.config[:exclude_routes].each { |route| routes.delete(route) }
        routes
      end
  
      def validate_options(type, options)
        case type
        when :b2bua
          raise ArgumentError, "If requesting a :b2bua you may not specify a :to" if options[:to]
        when :out_of_the_blue
          raise ArgumentError, "Must provide a :to and :from in options" if options[:to].nil? || options[:from].nil?
        else
          raise ArgumentError, "Unknown type of #{type}, must be :b2bua or :out_of_the_blue"
        end
      end
  
      ##
      # Provides the delimitter for Rayo to use for multiple route headers
      #
      # @return [String] value to use as the delimitter
      def delimitter; "|||"; end
  
      ##
      # Generates a UUID
      #
      # @return [String] a guid
      def uuid; SecureRandom.uuid.gsub('-', ''); end
  
      ##
      # Genertes the SIP to URI
      #
      # @param [Optional, Hash] options containing the :to if desired
      # @return [String] the string to be used for the SIP URI with the UVP
      def build_to(options={})
        if options[:to]
          "sip:#{options[:to]}@#{config[:uvp_address]}"
        else
          "sip:#{to}@#{config[:uvp_address]}"
        end
      end
  
      ##
      # Generates the from URI
      #
      # @param [Optional, Hash] options to be use to build the string
      # @return [String] the string to be used for the SIP URI with the UVP
      def build_from(options={})
        if options[:from]
          "tel:#{options[:from]}"
        else
          "tel:#{from}"
        end
      end
  
      ##
      # Returns a configuration value from the plugin's config
      #
      # @param [Symbol] key to return the value of
      # @return [String] value of the key
      def config; Adhearsion::IMS::Plugin.config.to_hash; end
  
      ##
      # Used to create a convenience method for filtering out the to/from in a call header
      def method_missing(method); extract_user_from variables[method]; end
  
      ##
      # Returns a extracted string to dial
      #
      # @param [Symbol] address to returm
      # @return [String] string that may be used to dial
      def extract_user_from(address)
        user = /sip:([^@]+)@/.match(address).to_a[1]
        # Add a US prefix if the user is all numeric
        if user =~ /^\d+$/
          user = "+#{user}" if user =~ /^1/
          user = "+1#{user}" unless user =~ /^\+1/
        end
        user
      end
    end
  end
end
