module MonkeyWrench
  class Member
    def initialize(list_member_info)
      @list_member_info = list_member_info
    end

    def interests
      if @list_member_info['merges']['INTERESTS']
        @list_member_info['merges']['INTERESTS'].split(', ')
      end
    end
    
    def method_missing(method, *args)
      if responds_to?(method)
        key_name = method.to_s
        @list_member_info[key_name] || @list_member_info['merges'][key_name] || @list_member_info['merges'][key_name.upcase]
      else
        super
      end
    end
    
    def responds_to?(method)
      key_name = method.to_s
      @list_member_info.has_key?(key_name) || 
        @list_member_info['merges'].has_key?(key_name) ||
        @list_member_info['merges'].has_key?(key_name.upcase)
    end
    
    def ==(other_member)
      !@list_member_info.keys.detect{|key| send(key) != other_member.send(key)}
    end
  end
end
