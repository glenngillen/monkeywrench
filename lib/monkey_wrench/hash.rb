require 'cgi'
module MonkeyWrench
  module Hash
 
    # Takes a block that returns a [key, value] pair
    # and builds a new hash based on those pairs
    # Courtesy of http://snuxoll.com/post/2009/02/13/ruby-better-hashcollect
    def collect_kv
      result = {}
      each do |k,v|
        new_k, new_v = yield k, v
        result[new_k] = new_v
      end
      result
    end
    
    def collect_kv!(&blk)
      replace(self.collect_kv(&blk))
    end
    
    def escape_keys!
      collect_kv!{|k,v| [CGI.escape(k.to_s), v]}
    end
    
    def to_mailchimp(index = nil, parent_name = nil)
      result = self.collect_kv do |k,v|
        if v.is_a?(Array) && v.first.is_a?(Hash)
          i = 0
          v = v.inject({}) do |acc,hash|
            acc.merge!(hash.to_mailchimp(i, k))
            i += 1
            acc
          end
        elsif v.is_a?(Hash)
          if parent_name
            v = v.collect_kv do |key,val| 
              keyname = CGI.escape("#{parent_name.to_s}[#{key.to_s.upcase}]")
              [keyname, val]
            end
          else
            v = { k => v }.to_mailchimp(nil, k)
          end
        end
        k = k.to_s
        k = "[#{index}][#{k.upcase}]" if index
        k = [parent_name, k].join if k != parent_name.to_s
        [CGI.escape(k), v]
      end
      if result.detect{|k,v| v.is_a?(Hash)}
        result.values.first
      else
        result
      end
    end
  end
end

class Hash
  include MonkeyWrench::Hash
end