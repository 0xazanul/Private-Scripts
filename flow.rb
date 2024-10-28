#!/usr/bin/env ruby

require 'optparse'

# Define options for command line arguments
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: script.rb -f domains.txt"

  opts.on("-f", "--file FILE", "File containing a list of domains") do |file|
    options[:file] = file
  end
end.parse!

# Check if file option is provided
if options[:file].nil?
  puts "Please provide a file with the -f option."
  exit
end

# Path to store output files
desktop_path = "/home/xab/Desktop/"

# Read the list of domains from the file
domains_file = options[:file]
domains = File.readlines(domains_file).map(&:chomp)

# Step 1: Run Subfinder and Assetfinder for subdomain enumeration
subdomains_file = File.join(desktop_path, "subdomains.txt")
File.open(subdomains_file, 'w') do |file|
  domains.each do |domain|
    puts "Finding subdomains for #{domain} using Subfinder..."
    system("subfinder -d #{domain} -silent", out: file)
    
    puts "Finding subdomains for #{domain} using Assetfinder..."
    system("assetfinder --subs-only #{domain}", out: file)
  end
end

# Step 2: Check for subdomain takeover with Subzy
puts "Checking subdomain takeover with Subzy..."
system("subzy run --targets #{subdomains_file}")

puts "Workflow complete! Subdomains and Subzy results are saved in #{desktop_path}."
