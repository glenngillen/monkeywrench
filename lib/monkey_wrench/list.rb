require 'cgi'
require 'monkey_wrench/list/list_finder'

module MonkeyWrench
  class List < MonkeyWrench::Base
    # Will compare another list against the current one and return true if 
    # they are the same (based on list ID)
    #
    # @example
    #   list1 = MonkeyWrench::List.find("0a649eafc3")
    #   list2 = MonkeyWrench::List.find("9f9d54a0c4")
    #   list3 = MonkeyWrench::List.find("0a649eafc3") # Same as list1!!
    #   list1 == list2 # false
    #   list1 == list3 # true
    # @param [MonkeyWrench::List] other_list Other list to compare against
    # @return [Boolean]
    def ==(other_list)
      other_list.is_a?(self.class) && self.id == other_list.id
    end

    # Returns all members for this list
    #
    # @example Find all members that have unsubscribed in the last 24 hours:
    #   MonkeyWrench.members(:status => "unsubscribed",
    #                        :since => Time.now - 86400)
    #
    # @param [Hash] options additional option to include when searching.
    # @option options [String] :status ('subscribed') Filter the list members by status. Can be one of the following: "subscribed", "unsubscribed", "cleaned", "updated".
    # @option options [DateTime] :since Return all members whose status has changed or whose profile has changed since this date/time (in GMT).
    # @option options [Integer] :start (0) For large datasets, the page number to start at.
    # @option options [Integer] :limit (100) For large datasets, the number of results to return. Upper limit is set at 15000.
    # @option options [Boolean] :full_details (true) Return full member details and not just email address and timestamp.
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
    # @example
    #   list = MonkeyWrench::List.find("0a649eafc3")
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

    # Updates details of list members
    #
    # @example Update a single member's email address
    #   list = MonkeyWrench::List.find("0a649eafc3")
    #   member = {:email => "foo@bar.com", :new_email => "bar@foo.com"}
    #   list.update_members(member)
    #
    # @example Update multiple members' email addresses
    #   list = MonkeyWrench::List.find("0a649eafc3")
    #   members = [{:email => "foo@bar.com", :new_email => "bar@foo.com"},
    #              {:email => "bob@bar.com", :new_email => "bob@foo.com"}]
    #   list.update_members(members)
    #
    # @param [Hash, Array<Hash>] members details of member(s) to update details 
    #   of. Members are matched based on the value of :email, to update the 
    #   email address assign the new address to :new_email. All other field 
    #   names are lowercase symbols representing the MERGEVAR name in 
    #   Mailchimp (e.g., FNAME is :fname)
    # @param [Hash] options additional options when updating members.
    # @option options [String] :email_type Change the email type preference for the member ('html', 'text', or 'mobile').
    # @option options [Boolean] :replace_interests (true) replace the interest groups provided (will append interest groups to existing values when false).
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
    # @example
    #   list = MonkeyWrench::List.find("0a649eafc3")
    #   list.member("glenn@rubypond.com")
    #
    # @param [String] email members email address
    # @return [MonkeyWrench::Member]
    def member(email)
      response = post(:id => self.id, :method => "listMemberInfo", :email_address => email)
      if response['error']
        raise response['error']
      else
        MonkeyWrench::Member.new(response)
      end
    end

    # Subscribes a new member to the list
    #
    # @example Subscribe a new email address
    #   list.subscribe("foo@bar.com")
    #
    # @example Subscribe a new member with extended details
    #   list.subscribe({:email => "foo@bar.com", :type => :html})
    #
    # @example Subscribe multiple new members
    #   subscribers = [{:email => "foo@bar.com", :type => :html},
    #                  {:email => "bar@foo.com", :type => :html}]
    #   list.subscribe(subscribe, :send_welcome => true, :double_optin => false)
    #
    # @param [String, Hash, Array<Hash>] contact_details the email address or hash of values for the new member
    # @param [Hash] opts options when adding new member
    # @option opts [Boolean] :send_welcome (false) if :double_optin if false and this is 
    #   true, send the lists 'Welcome Email' to the member(s). Will not send email if 
    #  updating an existing member.
    # @option opts [Boolean] :double_optin (true) send an opt-in confirmation email
    # @option opts [Boolean] :update_existing (false) update members that are already subscribed to the list or to return an error (false returns error)
    # @option opts [Boolean] :replace_interests (true) replace interest groups or append to existing interest groups (false appends to groups)
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

    # Unsubscribes a person (or list of people) from the list
    #
    # @example Unsubscribe a single user
    #   list = MonkeyWrench::List.find("0a649eafc3")
    #   list.unsubscribe("glenn@rubypond.com", :send_goodbye => true) # Unsubscribe a single person
    #
    # @example Unsubscribe a list of users
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
    # @example Opt-out a single user
    #   list = MonkeyWrench::List.find("0a649eafc3")
    #   list.opt_out("glenn@rubypond.com") # Opt-out a single person
    #
    # @example Opt-out a list of users
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

      def batch_size
        5000
      end

      def each_batch(subscribers, batch_size, &block) 
        i = 0
        while i < subscribers.size
          start = Time.now
          yield subscribers[i..(i+batch_size-1)], i
          i += batch_size
        end
      end

      def subscribe_in_batches(subscribers, opts)
        cumulative_response = { :success => 0, :errors => [] }
        each_batch(subscribers, batch_size) do |batch, i|
          response = subscribe_one_batch(batch, opts)
          cumulative_response[:success] += (response["success_count"] || 0)
          cumulative_response[:errors] += (response["errors"] || [])
        end
        cumulative_response
      end

      def subscribe_one_batch(subscribers, opts)
        params = { :id => self.id, :method => "listBatchSubscribe" }
        params[:double_optin] = opts[:double_optin] if opts.has_key?(:double_optin)
        params[:update_existing] = opts[:update_existing] if opts.has_key?(:update_existing)
        params[:replace_interests] = opts[:replace_interests] if opts.has_key?(:replace_interests)
        params.merge!({ :batch => subscribers }.to_mailchimp)
        post(params, :timeout => timeout_for_batch(subscribers))
      end

      def timeout_for_batch(batch)
        # 5 mins for a batch of 5000
        ((batch.size.to_f / 5000) * (5 * 60)).to_i
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
                  :email_address => email_address
                 }
        params.reject!{ |k,v| v.nil? }
        merge_vars = { :merge_vars => opts }.to_mailchimp
        params.merge!(merge_vars)
        params.merge!(:method => "listSubscribe", :id => self.id)
        post(params)
      end
  end
end
