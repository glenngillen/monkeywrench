require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'net/http'

begin 
  require "redgreen"
rescue LoadError; 
end

require File.expand_path(File.dirname(__FILE__)) + '/lib/fakeweb/lib/fake_web'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "#{File.dirname(__FILE__)}/../lib/monkey_wrench"

FakeWeb.allow_net_connect = false

class Test::Unit::TestCase
  protected

  def setup_config
    MonkeyWrench::Config.new(:apikey => "my-key", :datacenter => "my-dc")
  end
  
  def mock_response(method, api, dc, remote_method, params, fixture, is_success)
    params.merge!({ :method => remote_method, :output => :json, :apikey => api})
    form_params = map_form_params(params).gsub(/%5([b-d])/) {|s| s.upcase}  
    uri = "http://#{dc}.api.mailchimp.com/1.2/?#{form_params}"
    response = File.read(json_fixture_path(fixture, is_success))
    store_response(uri, params, response)
    FakeWeb.register_uri(method, uri, { :body => response, :content_type => 'application/json' })
  end
  
  def mock_chimp_post(method, params = {}, is_success = true, fixture = nil)
    mock_response(:post, "my-key", "my-dc", method, params, fixture || method, is_success)
  end
  
  def store_response(uri, params, response)
    @stored_responses ||= {}
    @stored_responses[uri] ||= {}
    @stored_responses[uri][params.collect_kv{|k,v| [k.to_s, v.to_s]}.inspect] = response
  end
  
  def get_response(uri, actual_params)
    response = @stored_responses[uri][actual_params.inspect]
    raise "Unable to handle request to #{uri} with params: #{actual_params.inspect}" unless response
    response
  end
  
  def map_form_params(params)
    request = Net::HTTP::Post.new("http://localhost/")
    request.set_form_data(params)
    request.body
  end

  def json_fixture_path(fixture, is_success)
    response = is_success ? "success" : "fail"
    File.join(File.dirname(__FILE__), "fixtures", "#{fixture}_#{response}.json")
  end
  
  def clear_fakeweb
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = false
  end

end
