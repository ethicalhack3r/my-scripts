#!/usr/bin/env ruby


if ARGV[0].nil?
  puts "Usage: ruby #{__FILE__} domains.txt"
  exit
end

domains = File.read(ARGV[0]).split("\n")

domains.each_with_index do |domain, index|
  p domain
  `java -jar /Users/ryan/Tools/ssl/TestSSLServer.jar #{domain} >> /Users/ryan/Desktop/ssl/#{domain}.txt`
end

exit
