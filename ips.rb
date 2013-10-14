#!/usr/bin/env ruby

#
# Lists IPs in a CIDR range. 
#

require 'ipaddress'

ips = IPAddress.parse "0.0.0.0/26"

ips.each do |ip|
  puts ip
end
