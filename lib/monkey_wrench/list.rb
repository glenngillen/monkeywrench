require 'cgi'

module MonkeyWrench
  class List < MonkeyWrench::Base
    
    def self.find_by_name(list_name)
      lists = find_all.detect{|list| list.name == list_name}
    end

    def ==(other_list)
      other_list.is_a?(self.class) && self.id == other_list.id
    end

    def self.find(id)
      new(:id => id)
    end
    
    def self.find_all
      lists = post({ :method => "lists" }).map do |list|
        List.new(list)
      end
    end

    def members(options = {})
      options.merge!(:id => self.id, :method => "listMembers")
      post(options)
    end 

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
