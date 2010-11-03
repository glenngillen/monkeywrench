$:.unshift File.expand_path("..", File.dirname(__FILE__))
require "test_helper"

class MonkeyWrench::BaseTest < Test::Unit::TestCase

  context "making an HTTP GET" do
    should "retry if HTTP GET times out" do
      retries = sequence('retries')
      response = mock('')
      response.stubs(:parsed_response).returns("the response")
      Kernel.stubs(:sleep).with(180).returns(180)
      MonkeyWrench::Base.stubs(:base_uri).returns('http://example.com')
      HTTParty::Request.any_instance.expects(:perform).in_sequence(retries).raises(Timeout::Error)
      HTTParty::Request.any_instance.expects(:perform).in_sequence(retries).raises(Timeout::Error)
      HTTParty::Request.any_instance.expects(:perform).in_sequence(retries).returns(response)
      assert_equal MonkeyWrench::Base.get({}), 'the response'
    end

    should "rethrow Timeout::Error if retry limit exceeded" do
      retries = sequence('retries')
      response = mock('')
      response.stubs(:parsed_response).returns("the response")
      MonkeyWrench::Base.stubs(:base_uri).returns('http://example.com')
      Kernel.stubs(:sleep).with(180).returns(180)
      HTTParty::Request.any_instance.expects(:perform).in_sequence(retries).raises(Timeout::Error)
      HTTParty::Request.any_instance.expects(:perform).in_sequence(retries).raises(Timeout::Error)
      assert_raise Timeout::Error do
        MonkeyWrench::Base.get({}, :retry_limit => 2)
      end
    end
  end

  context "making an HTTP POST" do
    should "retry if HTTP POST times out" do
      retries = sequence('retries')
      response = mock('')
      response.stubs(:parsed_response).returns("the response")
      MonkeyWrench::Base.stubs(:base_uri).returns('http://example.com')
      Kernel.stubs(:sleep).with(180).returns(180)
      HTTParty::Request.any_instance.expects(:perform).in_sequence(retries).raises(Timeout::Error)
      HTTParty::Request.any_instance.expects(:perform).in_sequence(retries).raises(Timeout::Error)
      HTTParty::Request.any_instance.expects(:perform).in_sequence(retries).returns(response)
      assert_equal MonkeyWrench::Base.post({}), 'the response'
    end

    should "rethrow Timeout::Error if retry limit exceeded" do
      retries = sequence('retries')
      response = mock('')
      response.stubs(:parsed_response).returns("the response")
      MonkeyWrench::Base.stubs(:base_uri).returns('http://example.com')
      Kernel.stubs(:sleep).with(180).returns(180)
      HTTParty::Request.any_instance.expects(:perform).in_sequence(retries).raises(Timeout::Error)
      HTTParty::Request.any_instance.expects(:perform).in_sequence(retries).raises(Timeout::Error)
      assert_raise Timeout::Error do
        MonkeyWrench::Base.post({}, :retry_limit => 2)
      end
    end
  end
end
