require File.dirname(__FILE__) + "/../test_helper"

class MonkeyWrench::ListTest < Test::Unit::TestCase
  context "subscribing to a list" do
    setup do
      setup_config
      mock_chimp_post(:lists)
      @list = MonkeyWrench::List.find("A test list")
      clear_fakeweb
    end
    
    context "multiple subscribers at once" do
      should "subscribe users" do
        form_params = {"batch[0][EMAIL]" => "mail@chimp.com", 
                  "batch[0][TYPE]" => "html", 
                  :id => "my-list-id"}
        mock_chimp_post(:listBatchSubscribe, form_params)

        subscribers = [{:email => "mail@chimp.com", :type => :html}]    
        expected = {:success => 1, :errors => []}      
        assert_equal expected, @list.subscribe(subscribers)
      end
      
      should "send welcome email" do
        form_params = {"merge_vars[FOO]" => "bar", :id => "my-list-id", 
                       :email => "mail@chimp.com", :type => :html,
                       :send_welcome => true}
        mock_chimp_post(:listSubscribe, form_params)

        subscribers = [{:email => "mail@chimp.com", :type => :html, :foo => "bar"}]    
        expected = {:success => 1, :errors => []}      
        assert_equal expected, @list.subscribe(subscribers, :send_welcome => true)
      end
      
      should "opt-out from list" do
      end
    end
    
    context "a single subscriber" do
      should "subsbscibe a user" do
        form_params = { :type=>:html, 
                        :update_existing=>true, 
                        "merge_vars[MY_DATE]"=>"20090101", 
                        :replace_interests=>false, 
                        :double_optin=>false, 
                        "merge_vars[FNAME]"=>"Joe", 
                        :id => "my-list-id",
                        :send_welcome=>true,
                        :email => "mail@chimp.com" }
        mock_chimp_post(:listSubscribe, form_params)

        params = { :type => :html,
                   :double_optin => false,
                   :update_existing => true,
                   :replace_interests => false,
                   :send_welcome => true,
                   :fname => "Joe",
                   :my_date => "20090101" 
                   }
        
        expected = {:success => 1, :errors => []}      
        assert_equal expected, @list.subscribe("mail@chimp.com", params)
      end
      
    end    
  end

  context "unsubscribing to a list" do
    setup do
      setup_config
      mock_chimp_post(:lists)
      @list = MonkeyWrench::List.find("A test list")
    end
    
    context "multiple subscribers at once" do
      should "unsubscribe" do
        form_params = {"emails[0]" => "mail@chimp.com", :id => "my-list-id"}      
        mock_chimp_post(:listBatchUnsubscribe, form_params)
        subscribers = ["mail@chimp.com"]
      
        expected = {:success => 1, :errors => []}
        assert_equal expected, @list.unsubscribe(subscribers)
      end
      
      should "delete subscriber" do
        form_params = {"emails[0]" => "mail@chimp.com", :id => "my-list-id",
                       :delete_member => true}
        mock_chimp_post(:listBatchUnsubscribe, form_params)
        subscribers = ["mail@chimp.com"]
      
        expected = {:success => 1, :errors => []}
        assert_equal expected, @list.unsubscribe(subscribers, :delete_member => true)
      end
      
      should "send goodbye" do
        form_params = {"emails[0]" => "mail@chimp.com", :id => "my-list-id",
                       :send_goodbye => true}
        mock_chimp_post(:listBatchUnsubscribe, form_params)
        subscribers = ["mail@chimp.com"]
      
        expected = {:success => 1, :errors => []}
        assert_equal expected, @list.unsubscribe(subscribers, :send_goodbye => true)
      end
      
      should "send unsubscribe notification" do
        form_params = {"emails[0]" => "mail@chimp.com", :id => "my-list-id",
                       :send_notify => true}
        mock_chimp_post(:listBatchUnsubscribe, form_params)
        subscribers = ["mail@chimp.com"]
      
        expected = {:success => 1, :errors => []}
        assert_equal expected, @list.unsubscribe(subscribers, :send_notify => true)
      end
    end
    
    context "a single subscriber" do
      should "unsubscribe" do
        form_params = { :email => "mail@chimp.com", :id => "my-list-id" }
        mock_chimp_post(:listUnsubscribe, form_params)

        expected = {:success => 1, :errors => []}      
        assert_equal expected, @list.unsubscribe("mail@chimp.com")
      end
    end
  end
  
  context "opting out of a list" do
    setup do
      setup_config
      mock_chimp_post(:lists)
      @list = MonkeyWrench::List.find("A test list")
    end
    
    context "multiple subscribers at once" do
      should "opt out" do
        form_params = { "batch[0][EMAIL]" => "mail@chimp.com", :id => "my-list-id" }
        mock_chimp_post(:listBatchSubscribe, form_params)
        form_params = { "emails[0]" => "mail@chimp.com", :id => "my-list-id" }
        mock_chimp_post(:listBatchUnsubscribe, form_params)
        subscribers = [{:email => "mail@chimp.com"}]
      
        expected = {:success => 1, :errors => []}
        assert_equal expected, @list.opt_out(subscribers)
      end
    end
    
    context "a single subscriber" do
      should "opt out" do
        form_params = { "batch[0][EMAIL]" => "mail@chimp.com", :id => "my-list-id" }
        mock_chimp_post(:listBatchSubscribe, form_params)
        form_params = { "emails[0]" => "mail@chimp.com", :id => "my-list-id" }
        mock_chimp_post(:listUnsubscribe, form_params)

        expected = {:success => 1, :errors => []}      
        assert_equal expected, @list.opt_out("mail@chimp.com")
      end
    end
  end
end