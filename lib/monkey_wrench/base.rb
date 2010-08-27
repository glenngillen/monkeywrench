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
    @@dryrun = false
    
    class << self
      def default_query_params
        { :output => "json", :apikey=> @@apikey}
      end
      
      def base_uri
        "http://#{datacenter}.api.mailchimp.com/1.2/"
      end

      def default_retry_limit
        3
      end

      def get(params, http_options = {})
        if @@dryrun
          puts "GET #{base_uri} #{params.merge(default_query_params).inspect}"
          return {}
        else
          robustly(http_options) do
            response = super(base_uri, http_options.merge(:query => params.merge(default_query_params)))
            handle_errors(response.parsed_response)
          end
        end
      end
      
      def post(params, http_options = {})
        if @@dryrun
          puts "POST #{base_uri} #{params.merge(default_query_params).inspect}"
          return {}
        else
          robustly(http_options) do
            post_params = params.dup
            get_params = default_query_params.merge(:method => post_params.delete(:method))
            response = super(base_uri, http_options.merge(:body => post_params, :query => get_params))
            handle_errors(response.parsed_response)
          end
        end
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
      def self.robustly(http_options, &block)
        retry_limit = http_options[:retry_limit] || default_retry_limit
        attempts = 0
        while attempts < retry_limit
          begin
            attempts += 1
            return yield
          rescue Timeout::Error => e
            if attempts == retry_limit
              raise e
            end
          end
        end
      end

      def get(*args)
        self.class.get(*args)
      end
    
      def post(*args)
        self.class.post(*args)
      end
    
  end
end
