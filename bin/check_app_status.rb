#!/usr/bin/env ruby

require 'optparse'
require 'net/http'
require 'json'

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

options = {}
optparse = OptionParser.new do|opts|
  opts.banner = "Nagios check script for app_status. See https://github.com/alexdean/app_status"

  options[:verbose] = false
  opts.on('-v', '--verbose', 'Output more information') do
    options[:verbose] = true
  end

  opts.on('-V', '--version', 'Output version information') do
    puts "0.0.1"
    exit OK
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit OK
  end

  opts.on('-u', '--url VAL', 'Url to monitor') do |i|
    options[:url] = i
  end

  opts.on('-a', '--auth', "HTTP basic auth in the form 'user:password'") do |i|
    user, password = i.split(':')
    options[:basic_auth] = {user: user, password: password}
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

if options[:verbose]
  print "Running with options: "
  puts options.inspect
  puts
end

check_data = Net::HTTP.get(URI(options[:url]))

if options[:verbose]
  print "Response body: "
  puts check_data
  puts
end

begin
  json = JSON.parse(check_data)
rescue JSON::ParserError => e
  exit_with CRIT, "Response from #{options[:url]} is not valid JSON."
end

if ! json['status_code']
  exit_with CRIT, "JSON response #{options[:url]} does not contain 'status_code'."
end

if json['details'].size > 0
  data = {}
  json['details'].each do |service, details|
    key = details['status_code']
    data[key] ||= []
    data[key] << "#{service}:'#{details['details']}'"
  end

  final = []
  status_names.each do |key,val|
    if data[key]
      final << "#{val}: #{data[key].join(', ')}"
    end
  end
  final = final.join("\n")
else
  final = "#{json['status'].upcase}. No details available."
end

exit_with json['status_code'], final
