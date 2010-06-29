home_path = `cd ~; pwd`.strip
if File.exists?("#{home_path}/.monkeywrench")
  puts "Loading config from #{home_path}/.monkeywrench"
  MonkeyWrench::Config.new("#{home_path}/.monkeywrench")
else
  puts "To automatically connect to Mailchimp put your credentials in a the file #{home_path}/.monkeywrench with the following format:"
  puts ""
  puts "mailchimp:"
  puts "  datacenter: us1 # Or whatever DC you use"
  puts "  apikey: your-api-key-goes-here"
  puts ""
end
include MonkeyWrench