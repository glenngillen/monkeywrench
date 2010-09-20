module MonkeyWrench
  class List < MonkeyWrench::Base
    # Finds a given list by name
    #
    # @example
    #   MonkeyWrench::List.find_by_name("My Example List")
    #
    # @param [String] list_name the list name
    # @return [MonkeyWrench::List] the first list found with a matching name
    def self.find_by_name(list_name)
      lists = find_all.detect{|list| list.name == list_name}
    end

    # Finds a given list by ID
    #
    # @example
    #   MonkeyWrench::List.find("0a649eafc3")
    #
    # @param [String] id the unique Mailchimp list ID
    # @return [MonkeyWrench::List] the list
    def self.find(id)
      find_all.find{|e| e.id == id}
    end

    # Finds all lists
    #
    # @example
    #   MonkeyWrench::List.find_all
    #
    # @return [Array<MonkeyWrench::List>]
    def self.find_all
      @@lists ||= post({ :method => "lists" }).map do |list|
        List.new(list)
      end
    end

    # Clears the List cache
    #
    # @example
    #   MonkeyWrench::List.clear!
    #
    # @return nil
    def self.clear!
      @@lists = nil
    end

    class << self
      alias :all :find_all
    end
  end
end
