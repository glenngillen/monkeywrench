$:.unshift File.expand_path("..", File.dirname(__FILE__))
require "test_helper"

class MonkeyWrench::ListTest < Test::Unit::TestCase
  context "converting a flat hash to a Mailchimp structured array" do
    setup do
      @example_hash = { :email_address => "mail@chimp.com", :type => :html }
    end
    
    should "include index keys" do
      assert @example_hash.to_mailchimp(0).keys.include?("%5B0%5D%5BEMAIL_ADDRESS%5D")
    end
    
    should "include parent parameter name in keys" do
      assert @example_hash.to_mailchimp(0, "batch").keys.include?("batch%5B0%5D%5BEMAIL_ADDRESS%5D")
    end
  end
  
  context "converting a hash with array values to a Mailchimp structured array" do
    setup do
      @example_hash = { :batch => [{ :email_address => "mail@chimp.com", :type => :html },
                                   { :email_address => "foo@bar.com", :type => :text }]}
    end
    
    should "flatten all nested values" do
      chimped = @example_hash.to_mailchimp
      assert chimped.keys.include?("batch%5B0%5D%5BEMAIL_ADDRESS%5D")
      assert chimped.keys.include?("batch%5B1%5D%5BEMAIL_ADDRESS%5D")
      
      chimp = chimped["batch%5B0%5D%5BEMAIL_ADDRESS%5D"]
      bar = chimped["batch%5B1%5D%5BEMAIL_ADDRESS%5D"]
      assert_equal "mail@chimp.com", chimp
      assert_equal "foo@bar.com", bar
    end
  end
  
  context "converting a nested hash" do
    setup do
      @example_hash = { :vars => { :email_address =>"mail@chimp.com", :type => :html } }
    end
    
    should "include index keys" do
      assert @example_hash.to_mailchimp.keys.include?("vars%5BEMAIL_ADDRESS%5D")
      assert @example_hash.to_mailchimp.keys.include?("vars%5BTYPE%5D")
    end

    should "convert symbols to strings" do
      assert_equal @example_hash.to_mailchimp['vars%5BTYPE%5D'], 'html'
    end

    should_eventually "recursively convert hashes" do
      example = { :a => { :b => { :c => 1 }}}
      expected = {"a%5BV%5D%5BC%5D" => 1}
      assert_equal expected, example.to_mailchimp
    end
  end
end
