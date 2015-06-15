#!/usr/bin/env ruby

#
# Script that runs a regular expression against the response headers of a list of URLs.
# Useful for checking if a list of URLs have HSTS, the Server content, etc
#

require 'typhoeus'
require 'uri'

if ARGV[0].nil?
  puts "Usage: ruby #{__FILE__} \"regex\" urls.txt"
  exit
end

regex  = ARGV[0]
urls   = File.read(ARGV[1]).split("\n")

urls.each_with_index do |url, index|
  url = URI.parse(URI.encode(url))

  response = Typhoeus.get( url.to_s,
                           ssl_verifyhost: 0,
                           ssl_verifypeer: false,
                           followlocation: true,
                           headers: {'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:38.0) Gecko/20100101 Firefox/38.0'},
                           timeout: 1000 )

  matches = response.response_headers.scan(Regexp.new(regex, true))

  puts
  puts "[#{index}] #{url}"
  matches.each { |match| puts match }
end

exit
