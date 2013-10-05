#!/usr/bin/env ruby

# This is a Nagios script intended to check the JSON output from an application
# using app_status to expose some monitoring data.
#
# `./check_app_status.rb --help` for usage information.
#

require 'optparse'
require 'net/http'
require 'json'
require 'time'

  OK = 0
WARN = 1
CRIT = 2
 UNK = 3

status_names = {
  3 => 'UNK',
  2 => 'CRIT',
  1 => 'WARN',
  0 => 'OK'
}

def exit_with(status, message)
  puts message
  exit status
end

def when_verbose
  msg = yield
  puts "#{Time.now.iso8601}  #{msg}" if $verbose
end

options = {
  timeout: 10
}

optparse = OptionParser.new do|opts|
  opts.banner = "Nagios check script for app_status. See https://github.com/alexdean/app_status"

  $verbose = false
  opts.on('-v', '--verbose', 'Output more information') do
    $verbose = true
  end

  opts.on('-V', '--version', 'Output version information') do
    puts "0.0.1"
    exit OK
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit OK
  end

  opts.on('-u', '--url VAL', 'Url to monitor. ex: http://localhost:3000/status') do |i|
    options[:url] = i
  end

  opts.on('-a', '--auth VAL', "HTTP basic auth in the form 'user:password'") do |i|
    user, password = i.split(':')
    options[:user] = user
    options[:password] = password
  end

  opts.on('-t', '--timeout VAL', "In seconds. Includes time required for all checks to complete.") do |i|
    options[:timeout] = i.to_i
  end
end

begin
  optparse.parse!
rescue OptionParser::InvalidOption => e
  exit_with CRIT, e
end

if ! options[:url]
  exit_with CRIT, '--url is required'
end

when_verbose { "options: #{options.inspect}"}

uri = URI(options[:url])
exit_with CRIT, "Malformed URL : #{options[:url]}" if ! uri.respond_to?(:request_uri)
request = Net::HTTP::Get.new(uri.request_uri)

if options[:user]
  request.basic_auth options[:user], options[:password]
  when_verbose {"basic auth user:'#{options[:user]}' password:'#{options[:password]}'"}
end

http = Net::HTTP.new(uri.host, uri.port)
http.read_timeout = options[:timeout]
when_verbose {"timeout: #{options[:timeout]}s"}
use_ssl = uri.scheme == 'https' ? true : false
http.use_ssl = use_ssl
when_verbose {"using ssl: #{use_ssl}"}

response = nil
begin
  response = http.request(request)
rescue Exception => e
  exit_with CRIT, "Exception when reading #{options[:url]}. #{e.class} #{e.message}."
end

response_code = response.code
if response_code != '200'
  exit_with CRIT, "Got #{response_code} response from #{options[:url]}."
end

check_data = response.body
when_verbose { "response body: #{check_data}"}

begin
  json = JSON.parse(check_data)
rescue JSON::ParserError => e
  exit_with CRIT, "Response from #{options[:url]} is not valid JSON."
end

if ! json['status_code']
  exit_with CRIT, "JSON response #{options[:url]} does not contain 'status_code'."
end

final = ""
line_len = 0
# build output
if json['checks'].size > 0
  data = {}
  max_size = 0

  # sort checks by severity.
  json['checks'].each do |service, check|
    code = check['status_code']
    max_size = [max_size, service.size].max
    data[code] ||= []
    data[code] << [service, check['details']]
  end

  lines = []
  # sort in severity order
  status_names.each do |code,status|
    if data[code]
      lines += data[code].sort.
        map {|i| status.ljust(4) +'   '+ i[0].ljust(max_size) +"   "+ i[1]}
      lines << nil
    end
  end

  # add group separators & build final report
  line_len = lines.compact.map(&:size).max
  lines.each do |line|
    if line
      final += line + "\n"
    else
      final += ('-'*line_len) + "\n"
    end
  end

else
  msg = "#{json['status'].upcase}. No individual check details available.\n"
  final += msg
  line_len = msg.strip.size
end

final += "#{json['run_time_ms']} ms".rjust(line_len)

puts if $verbose

exit_with json['status_code'], final
