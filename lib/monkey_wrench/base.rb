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
        json = super(base_uri, :query => params.merge(default_options))
        parse_json(json)
      end
      
      def post(params)
        json = super(base_uri, :query => params.merge(default_options))
        parse_json(json)
      end
      
      def parse_json(json)
        return true if json == "true"
        if Object.const_defined?("Yajl")
          parser = Yajl::Parser.new
          parsed = parser.parse(json.to_s)
        else
          parsed = JSON.parse(json)
        end
        objects = handle_errors(parsed)
        objects
      end
      
      def handle_errors(objects)
        return objects unless objects.respond_to?(:has_key?)
        
        if objects.has_key?("error")
          objects.collect_kv!{|k,v| [k.sub("error","message"), v]}
          objects.replace({ "error" => MonkeyWrench::Error.new(objects) })
        elsif objects.has_key?("errors")
          objects["errors"] = objects["errors"].map do |err|
            MonkeyWrench::Error.new(err)
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
