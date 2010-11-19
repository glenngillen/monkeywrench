require "httparty"
base_dir = File.join(File.dirname(__FILE__), "monkeywrench")
["base", "config", "hash", "list", "error", "member"].each do |lib|
  require File.join(base_dir, lib)
end

begin
  OpenStruct.class_eval { undef :id, :type }
rescue NameError
end
