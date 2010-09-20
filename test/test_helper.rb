require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'net/http'
require 'mocha'
require 'webmock/test_unit'
require 'yajl/json_gem'

begin
  require 'redgreen'
rescue LoadError;
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "#{File.dirname(__FILE__)}/../lib/monkey_wrench"

class Test::Unit::TestCase
  include WebMock

  protected

  def setup_config
    MonkeyWrench::Config.new(:apikey => "my-key", :datacenter => "my-dc")
    MonkeyWrench::List.clear!
  end

  def uri_for_remote_method(remote_method) 
    get_params = { :method => remote_method, :output => :json, :apikey => "my-key"}
    query_string = map_form_params(get_params).gsub(/%5([b-d])/) {|s| s.upcase}
    "http://my-dc.api.mailchimp.com/1.2/?#{query_string}"
  end

  def mock_chimp_posts(remote_method, sequence)
    uri = uri_for_remote_method(remote_method)
    sequence.each do |response|
      response_body = canned_response(fixture_filename(response[:fixture] || remote_method, response[:is_success]))
      stub_request(:post, uri).with(:body => response[:params]).
        to_return(:body => response_body, :headers => {'Content-Type' => 'application/json'})
    end
  end

  def mock_chimp_post(remote_method, post_params = {}, is_success = true, fixture = nil)
    mock_chimp_posts remote_method, [{:params => post_params, :is_success => is_success, :fixture => fixture}]
  end

  def escape(string)
    URI.escape(string, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end

  def map_form_params(params)
    params.map { |k,v| escape(k.to_s) + '=' + escape(v.to_s) }.join('&')
  end

  def canned_response(filename)
    File.read(fixture_path(filename))
  end

  def fixture_filename(fixture, is_success)
    outcome = is_success ? "success" : "fail"
    "#{fixture}_#{outcome}.json"
  end

  def fixture_path(filename)
    File.join(File.dirname(__FILE__), "fixtures", filename)
  end
end
