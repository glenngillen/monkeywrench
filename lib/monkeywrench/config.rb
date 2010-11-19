require 'yaml'
module MonkeyWrench
  class Config < MonkeyWrench::Base
    # Establishes a connection to the Mailchimp API.
    #
    # Can be called with either a path to a file containing credentials, or 
    # a hash of credentials. The formats of each are:
    #
    # File:
    #   mailchimp:
    #     datacenter: us1 # Or whatever DC you use
    #     apikey: your-api-key-goes-here
    # Hash:
    #   { :datacenter => "us1", :apikey => "your-api-key-goes-here"}
    #
    # @example
    #     MonkeyWrench::Config.new(:datacenter => "us1", 
    #                              :apikey => "your-api-key-goes-here")
    #
    # @param [String, Hash] credentials accepts either a String pointing to a file
    # containing the credentials, or a hash of credentials. 
    def initialize(credentials)
      if credentials.is_a?(String)
        config = YAML.load_file(credentials)["mailchimp"]
        config.collect_kv!{|k,v| [k.to_sym, v]}
      else
        config = credentials
      end
      @@apikey = config[:apikey]
      @@datacenter = config[:datacenter]
      @@dryrun = config[:dryrun] || false
      super({})
    end
  end
end
