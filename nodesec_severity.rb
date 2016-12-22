#!/usr/bin/env ruby

require 'typhoeus'
require 'uri'
require 'nokogiri'

url    = 'https://nodesecurity.io/advisories/'
ids    = ARGV[0].split(',')
cvsses = {}

ids.each do |id|
  new_url = URI.parse(url).merge(id)

  response = Typhoeus.get(  new_url.to_s,
                            :ssl_verifyhost => 0,
                            :ssl_verifypeer => false,
                            :followlocation => true,
                            :headers => {'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36'},
                            :timeout => 1000 )

  cvsses[new_url] = Nokogiri::HTML(response.body).css('.cvss-score').text
end

cvsses.sort_by {|_key, value| value}.reverse.each do |key, value|
  p "#{key} CVSS:#{value}"
end

exit
