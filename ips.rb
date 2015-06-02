#!/usr/bin/env ruby

#
# Lists IPs in a CIDR range. 
#

require 'ipaddress'

ips = IPAddress.parse ""

ips.each do |ip|
  puts ip
end
