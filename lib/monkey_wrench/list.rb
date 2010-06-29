require 'cgi'

module MonkeyWrench
  class List < MonkeyWrench::Base

    # Finds a given list by name
    #
    #   MonkeyWrench.find_by_name("My Example List")
    #
    # @param [String] list_name the list name
    # @return [MonkeyWrench::List] the first list found with a matching name
    def self.find_by_name(list_name)
      lists = find_all.detect{|list| list.name == list_name}
    end
    
    # Will compare the another list against the current one and return true if 
    # they are the same
    #
    #   list1 = MonkeyWrench.find("0a649eafc3")
    #   list2 = MonkeyWrench.find("9f9d54a0c4")
    #   list3 = MonkeyWrench.find("0a649eafc3") # Same as list1!!
    #   list1 == list2 # false
    #   list1 == list3 # true
    # @param [MonkeyWrench::List] other_list Other list to compare against
    # @return [Boolean]
    def ==(other_list)
      other_list.is_a?(self.class) && self.id == other_list.id
    end

    # Finds a given list by ID
    #
    #   MonkeyWrench::List.find("0a649eafc3")
    #
    # @param [String] id the unique Mailchimp list ID
    # @return [MonkeyWrench::List] the list
    def self.find(id)
      new(:id => id)
    end
    
    # Finds all lists
    #
    #   MonkeyWrench::List.find_all
    #
    # @return [Array<MonkeyWrench::List>] 
    def self.find_all
      lists = post({ :method => "lists" }).map do |list|
        List.new(list)
      end
    end
    class << self
      alias :all :find_all
    end
    
    # Returns all members for this list
    #
    # For example, to find all members that have unsubscribed in the last 24 hours:
    #
    #   MonkeyWrench.members(:status => "unsubscribed",
    #                        :since => Time.now - 86400)
    #
    # @param [Hash] options additional option to include when searching.
    # @option options [String] :status ('subscribed') Filter the list members by status. Can be one of the following: "subscribed", "unsubscribed", "cleaned", "updated".
    # @option options [DateTime] :since Return all members whose status has changed or whose profile has changed since this date/time (in GMT).
    # @option options [Integer] :start (0) For large datasets, the page number to start at.
    # @option options [Integer] :limit (100) For large datasets, the number of results to return. Upper limit is set at 15000.
    # @option options [Boolean] :full_details (true) Return full subscriber details and not just email address and timestamp.
    # @return [Array<MonkeyWrench::Member>] 
    def members(options = {})
      if options[:since]
        options[:since] = options[:since].strftime("%Y-%m-%d %H:%M:%S")
      end
      options.merge!(:id => self.id, :method => "listMembers")
      response = post(options)
      if options[:full_details]
        response.map do |response_user|
          member(response_user["email"])
        end
      else
        response.map do |response_user|
          MonkeyWrench::Member.new(response_user)
        end
      end
    end 

    # Enumerates over each member and executes the provided block. Will 
    # automatically page and batch requests for members.
    #
    #   list = MonkeyWrench.find("0a649eafc3")
    #   emails = []
    #   list.each_member do |member|
    #     emails << member.email
    #   end
    #
    # @param [Proc] &block code to execute for each member
    def each_member(&block) 
      page = 0
      loop do
        batch = members(:start => page, :limit => 15000)
        break if batch.empty?
        batch.each do |member|
          yield member
        end
        page += 1
      end
    end
    
    def update_members(members, options = {})
      members = members.is_a?(Array) ? members : [members]
      options.merge!(:id => self.id, :method => "listUpdateMember")
      members.each do |member|
        mailchimp_args = {:email_address => member[:email]}
        member[:email] = member[:new_email]
        member.delete(:new_email)
        mailchimp_args.merge!({ :merge_vars => member }.to_mailchimp)
        post(options.merge(mailchimp_args))
      end
    end
    
    # Find a member in this list with the given email address
    #
    #   list = MonkeyWrench::List.find("0a649eafc3")
    #   list.member("glenn@rubypond.com")
    #
    # @param [String] email subscribers email address
    # @return [MonkeyWrench::Member]
    def member(email)
      response = post(:id => self.id, :method => "listMemberInfo", :email_address => email)
      if response['error']
        raise response['error']
      else
        MonkeyWrench::Member.new(response)
      end
    end

    def subscribe(contact_details, opts = {})
      if contact_details.is_a?(Array)
        return subscribe_many(contact_details, opts)
      else
        if contact_details.is_a?(Hash)
          email_address = contact_details.delete(:email)
          opts = opts.merge(contact_details)
        else
          email_address = contact_details
        end        
        subscribe_one(email_address, opts)
        return { :success => 1, :errors => []}
      end
    end
    
    # Unsubscribers a person (or list of people) from the list
    #
    #   list = MonkeyWrench::List.find("0a649eafc3")
    #   list.unsubscribe("glenn@rubypond.com", :send_goodbye => true) # Unsubscribe a single person
    #
    #   emails = ["glenn@rubypond.com", "me@glenngillen.com"]
    #   list.unsubscribe(emails, :send_goodbye => true) # Unsubscribe multiple people at once
    #
    # @param [String, Array<String>] email address(es) of people to unsubscribe.
    # @param [Hash] opts additional option to include when unsubscribing.
    # @option opts [Boolean] :delete_member (false) completely delete the member from your list instead of just unsubscribing.
    # @option opts [Boolean] :send_goodbye (true) send the goodbye email to the email addresses.
    # @option opts [Boolean] :send_notify (false) send the unsubscribe notification email to the address defined in the list email notification settings.
    # @return [Hash] contains 2 keys. :success contains the number of successful actions, :error a list of all errors.
    def unsubscribe(emails, opts = {})
      emails = [*emails]
      params = { :method => "listBatchUnsubscribe", 
                 :id => self.id }
      params[:delete_member] = opts[:delete_member] if opts.has_key?(:delete_member)
      params[:send_goodbye] = opts[:send_goodbye] if opts.has_key?(:send_goodbye)
      params[:send_notify] = opts[:send_notify] if opts.has_key?(:send_notify)
      params.merge!({ :emails => emails }.to_mailchimp)
      response = post(params)
      return { :success => response["success_count"],
               :errors => response["errors"] }
    end
    
    # Will flag the email(s) as opted-out for all future mailing for this list
    #
    #   list = MonkeyWrench::List.find("0a649eafc3")
    #   list.opt_out("glenn@rubypond.com") # Opt-out a single person
    #
    #   emails = ["glenn@rubypond.com", "me@glenngillen.com"]
    #   list.opt_out(emails) # Opt-out multiple people at once
    #
    # @param [String, Array<String>] email address(es) of people to opt-out.
    # @return [Hash] contains 2 keys. :success contains the number of successful actions, :error a list of all errors.
    def opt_out(emails)
      emails = [*emails]      
      subscribe(emails.map{|email| { :email => email }})
      unsubscribe(emails, :send_goodbye => false, :send_notify => false)
    end
  
    private
      def self.reserved_keys
        [:email, :type, :double_optin, :update_existing, :replace_interests, 
         :send_welcome, :emails, :send_notify, :send_goodbye, :delete_member]
      end
      
      def subscribe_many(subscribers, opts = {})
        if opts[:send_welcome]
          subscribe_one_at_a_time(subscribers, opts)
        else
          subscribe_in_batches(subscribers, opts)
        end
      end

      def subscribe_in_batches(subscribers, opts)
        cumulative_response = { :success => 0, :errors => [] }
        i = 0
        while i < subscribers.size
          response = subscribe_one_batch(subscribers[i..i+9], opts)
          cumulative_response[:success] += response['success_count']
          cumulative_response[:errors] += response['errors']
          i += 10
        end
        cumulative_response
      end

      def subscribe_one_batch(subscribers, opts)
        params = { :id => self.id, :method => "listBatchSubscribe" }
        params[:double_optin] = opts[:double_optin] if opts.has_key?(:double_optin)
        params[:update_existing] = opts[:update_existing] if opts.has_key?(:update_existing)
        params[:replace_interests] = opts[:replace_interests] if opts.has_key?(:replace_interests)
        params.merge!({ :batch => subscribers }.to_mailchimp)
        post(params)
      end

      def subscribe_one_at_a_time(subscribers, opts)
        cumulative_response = { :success => 0, :errors => [] }
        subscribers.each do |subscriber|
          params = opts.merge(subscriber)
          params.delete(:email)
          if subscribe_one(subscriber[:email], params) == true
            cumulative_response[:success] += 1
          else
            cumulative_response[:errors] << response["error"]
          end
        end
        cumulative_response
      end

      def subscribe_one(email_address, opts = {})
        params = {
                  :type => opts.delete(:type),
                  :double_optin => opts.delete(:double_optin),
                  :update_existing => opts.delete(:update_existing),
                  :replace_interests => opts.delete(:replace_interests),
                  :send_welcome => opts.delete(:send_welcome),
                  :email => email_address
                 }
        params.reject!{ |k,v| v.nil? }
        merge_vars = { :merge_vars => opts }.to_mailchimp
        params.merge!(merge_vars)
        params.merge!(:method => "listSubscribe", :id => self.id)
        post(params)
      end
  end
end
