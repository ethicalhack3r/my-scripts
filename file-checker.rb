#!/usr/bin/env ruby

#
# This script takes a filename or directory as an argument as well as a list of URLs. 
# It will check every URL for that filename/directory and output the status code.
# Useful if you want to check, phpinfo.php exists on multiple domains for example.
# Example: ruby file-checker.rb filename urls.txt
#
# By: Ryan Dewhurst
#
#

require 'typhoeus'
require 'uri'

puts "Usage: filename urls.txt" if ARGV[0].nil?

filename  = ARGV[0]
urls      = File.read(ARGV[1]).split("\n")

urls.each do |url|
  url = URI.parse(URI.encode(url)).merge(filename)

  response = Typhoeus.get(  url.to_s,
                            :ssl_verifyhost => 0,
                            :ssl_verifypeer => false,
                            :followlocation => true,
                            :headers => {'User-Agent' => 'Mozilla'},
                            :timeout => 1000 )

  puts "#{url} #{response.code}"
end

exit
