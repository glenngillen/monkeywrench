begin
  require 'yajl'
rescue LoadError
  require 'json'
end
require 'ostruct'
module MonkeyWrench
  class Base < OpenStruct
    include HTTParty

    @@apikey = nil
    @@datacenter = nil
    
    class << self
      def default_options
        { :output => "json", :apikey=> @@apikey}
      end
      
      def base_uri
        "http://#{datacenter}.api.mailchimp.com/1.2/"
      end

      def get(params)
        response = super(base_uri, :query => params.merge(default_options))
        handle_errors(response.parsed_response)
      end
      
      def post(params)
        response = super(base_uri, :query => params.merge(default_options))
        handle_errors(response.parsed_response)
      end
      
      def handle_errors(objects)
        return objects unless objects.respond_to?(:has_key?)
        
        if objects.has_key?("error")
          objects.replace({ "error" => MonkeyWrench::Error.new(objects['error'], objects['code']) })
        elsif objects.has_key?("errors")
          objects["errors"] = objects["errors"].map do |err|
            message = err.delete('message')
            code = err.delete('code')
            MonkeyWrench::Error.new(message, code, err)
          end
        end
        objects
      end

      def apikey
        @@apikey
      end
      
      def datacenter
        @@datacenter
      end
    end
    
    private
      def get(params)
        self.class.get(params)
      end
    
      def post(params)
        self.class.post(params)
      end
    
  end
end
