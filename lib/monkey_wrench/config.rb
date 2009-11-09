require 'yaml'
module MonkeyWrench
  class Config < MonkeyWrench::Base
    def initialize(credentials)
      if credentials.is_a?(String)
        config = YAML.load_file(credentials)["mailchimp"]
        config.collect_kv!{|k,v| [k.to_sym, v]}
      else
        config = credentials
      end
      @@apikey = config[:apikey]
      @@datacenter = config[:datacenter]
      super({})
    end
  end
end