require 'cgi'
module MonkeyWrench
  class List < MonkeyWrench::Base
    
    def self.find(list_name)
      lists = find_all.detect{|list| list.name == list_name}
    end
    
    def self.find_all
      lists = post({ :method => "lists" }).map do |list|
        List.new(list)
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
  
    private
      def self.reserved_keys
        [:email, :type, :double_optin, :update_existing, :replace_interests, :send_welcome]
      end
      
      def subscribe_many(subscribers, opts = {})
        if opts[:send_welcome]
          i = 0
          errors = []
          subscribers.each do |subscriber|
            email_address = subscriber[:email]
            params = opts.merge(subscriber)
            params.delete(:email)

            response = subscribe_one(email_address, params)
            if response == true
              i += 1
            else
              errors << response["error"]
            end          
          end
          return { :success => i, :errors => errors}
        else
          batch = { :batch => subscribers }.to_mailchimp
          params = { :method => "listBatchSubscribe", 
                     :id => self.id }
          params[:double_optin] = opts[:double_optin] if opts.has_key?(:double_optin)
          params[:update_existing] = opts[:update_existing] if opts.has_key?(:update_existing)
          params[:replace_interests] = opts[:replace_interests] if opts.has_key?(:replace_interests)
          params.merge!(batch)
          response = post(params)
          return { :success => response["success_count"],
                   :errors => response["errors"] }        
        end
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
        response = post(params)
      end
  end
end