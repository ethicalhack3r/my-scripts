#!/usr/bin/env ruby

#
# Requests a list of URLs through a proxy.
#

require 'typhoeus'

urls  = File.open(ARGV.join).read.split("\n")
proxy = 'http://127.0.0.1:8080'


urls.each_with_index do |url, index|
  response = Typhoeus.get(url, proxy: proxy, followlocation: true)
  puts "#{index} - #{url} [#{response.code}]"
end
