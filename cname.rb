#!/usr/bin/env ruby

require 'resolv'
require 'colorize'
require 'optparse'
require 'thread'

THREAD_COUNT = 10

def print_banner
  puts "
   ____                          _____  _ _            
  |  _ \\ ___  _   _ _ __ ___ ___|  ___|(_) | ___ _ __  
  | |_) / _ \\| | | | '__/ __/ _ \\ |_   | | |/ _ \\ '_ \\ 
  |  __/ (_) | |_| | | | (_|  __/  _|  | | |  __/ | | |
  |_|   \\___/ \\__,_|_|  \\___\\___|_|    |_|_|\\___|_| |_|
  ".colorize(:light_blue)
  puts "Domain CNAME Checker (Optimized)".colorize(:yellow)
  puts "=============================================".colorize(:green)
end

def check_cname(domain)
  cname_record = nil
  Resolv::DNS.open do |dns|
    resources = dns.getresources(domain, Resolv::DNS::Resource::IN::CNAME)
    cname_record = resources.empty? ? nil : resources.first.name.to_s
  end
  cname_record
rescue StandardError => e
  "Error: #{e.message}"
end

def print_cname_details(domain, cname)
  if cname.nil? || cname.empty?
    puts "#{domain}: No CNAME found.".colorize(:red)
  elsif cname.start_with?("Error")
    puts "#{domain}: #{cname}".colorize(:red)
  else
    puts "#{domain}: CNAME points to #{cname}".colorize(:green)
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: domain_cname_checker_optimized.rb -f domains.txt"

  opts.on("-f", "--file FILE", "File containing list of domains") do |file|
    options[:file] = file
  end
end.parse!

if options[:file].nil?
  puts "Please provide a file containing domains with -f option.".colorize(:red)
  exit
end

begin
  domains = File.readlines(options[:file]).map(&:strip)
rescue Errno::ENOENT
  puts "File not found: #{options[:file]}".colorize(:red)
  exit
end

# Strip any protocols like http:// or https:// from domains
domains.map! do |domain|
  domain.gsub(/^https?:\/\//, '') # Remove http:// or https://
end

print_banner

queue = Queue.new
domains.each { |domain| queue << domain }

mutex = Mutex.new

def process_queue(queue, mutex)
  while !queue.empty?
    domain = queue.pop(true) rescue nil
    next if domain.nil?

    cname = check_cname(domain)
    mutex.synchronize do
      print_cname_details(domain, cname)
    end
  end
end

threads = []
THREAD_COUNT.times do
  threads << Thread.new { process_queue(queue, mutex) }
end

threads.each(&:join)
