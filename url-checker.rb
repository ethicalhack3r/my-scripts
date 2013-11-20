#!/usr/bin/env ruby

#
# Takes a list of URLs and sees which respond or not, useful for scoping large list of URLs.
#

require 'typhoeus'

url_list    = ARGV[0]
@ua         = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:24.0) Gecko/20100101 Firefox/24.0"
@good_sites = []
@bad_sites  = []
@timeouts   = []

def add_http_scheme(url)
  url =~ /^https?/ ? url : "http://#{url}"
end

def add_https_scheme(url)
  url =~ /^https?/ ? url : "https://#{url}"
end

def request(url)
  Typhoeus::Request.get(url,
  						:ssl_verifyhost => 0,
  						:ssl_verifypeer => false,
  						:followlocation => true,
  						:headers => {'User-Agent' => @ua},
  						:timeout => 1)
end

if File.exists?(url_list)
  file = File.open(url_list)
 else
  puts "ERROR: File #{url_list} does not exist!"
  exit
 end

file.each_line do |url|
  url = url.chop
  
  http_url  = add_http_scheme(url)
  https_url = add_https_scheme(url)

  http_response  = request(http_url)
  https_response = request(https_url)

  puts "Checking: #{http_url} [#{http_response.code}]"
  puts "Checking: #{https_url} [#{https_response.code}]"

  # HTTP 
  if http_response.code == 200
  	@good_sites << http_url
  elsif http_response.timed_out?
  	@timeouts << http_url
  	@bad_sites << http_url
  else
  	@bad_sites << http_url
  end

  # HTTPS
  if https_response.code == 200
  	@good_sites << https_url
  elsif https_response.timed_out?
  	@timeouts << https_url
  	@bad_sites << https_url
  else
  	@bad_sites << https_url
  end
end

puts
puts "| There were #{@good_sites.length} sites that responded with a 200 code:"
puts
@good_sites.each do |site|
  puts site
end

puts
puts "| There were #{@timeouts.length} sites that timedout:"
puts
@timeouts.each do |site|
  puts site
end

puts
puts "| There were #{@bad_sites.length} sites that timedout or returned a response other than 200:"
puts
@bad_sites.each do |site|
  puts site
end

