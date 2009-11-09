require "httparty"
base_dir = File.join(File.dirname(__FILE__), "monkey_wrench")
["base", "config", "hash", "list", "error"].each do |lib|
  require File.join(base_dir, lib)
end

OpenStruct.class_eval { undef :id, :type }