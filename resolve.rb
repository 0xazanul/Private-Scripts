require 'socket'
require 'colorize'

begin
  file = File.open(ARGV[0], "r")
rescue
  puts "Usage: ruby resolve.rb filename (where filename contains a list of domains)"
  exit
end

file.each_line do |subdomain|
  # Strip whitespace and remove http/https from the domain
  clean_subdomain = subdomain.strip.sub(/^https?:\/\//, '')

  begin
    color = :green
    ip = IPSocket::getaddress(clean_subdomain)
  rescue
    color = :red
    ip = "unknown"
  end

  puts "#{clean_subdomain}: #{ip}".colorize(color)
  system("nmap -F #{ip}") unless ip.eql?("unknown")
  puts
  puts "+-----------------------------------------------------------------------------------+"
  puts
end
