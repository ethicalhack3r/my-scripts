#!/usr/bin/env ruby

# gem install dalli -> https://github.com/mperham/dalli

require 'dalli'
require 'net/telnet'

@server     = 'remote_server_ip'
@port       = '11211'
@serverport = "#{@server}:#{@port}"

begin
  @dc = Dalli::Client.new(@serverport, compress: true, socket_timeout: 5)
rescue Dalli::NetworkError
  puts "[!] Couldn't connect to remote host #{serverport}"
  exit
end

#
# Extract the slabs from the items stats.
# Returns a unique array of slabs.
#
def slabs
  slabs = []

  @dc.stats(:items)[@serverport].each_pair do |key, value|
    slabs << key.match(/^items:(\d*):/)[1]
  end

  slabs = slabs.uniq - [""]

  puts
  puts "[*] Identified #{slabs.size} slabs..."

  slabs
end

#
# Extract the keys using stats cachedump:
# http://www.darkcoding.net/software/memcached-list-all-keys/
# https://gist.github.com/bkimble/1365005
# Returns an array of keys.
#
def keys(slabs)
  keys = []

  telnet = Net::Telnet::new('Host'       => @server,
                            'Port'       => @port,
                            'Timeout'    => 15,
                            'Telnetmode' => false,
                            'Waittime'   => 5)

  slabs.each do |slab|
    sleep 0.5 # don't want to flood the server

    begin
      telnet.cmd('String' => "stats cachedump #{slab} 100", 'Match' => /^END/) { |output| keys << output.scan(/^ITEM\s([\w-]*)\s/) }
    rescue => e
      puts "[!] Something is wrong when getting slabs #{e}"
      next
    end
  end

  telnet.close

  keys = keys.flatten.uniq
  puts "[*] Identified #{keys.size} keys..."

  keys
end

#
# Use the key name to grab the key value
#
def values(found_slabs)
  keys(found_slabs).each do |key|
    begin
      puts "[*] Getting value for #{key} key..."
      value = @dc.get(key)
      puts value if value
    rescue => e
      # puts "[!] Something went wrong #{e}"
      next
    end
  end
end

#
# Dumps the memcached stats
#
def stats
  @dc.stats[@serverport].each_pair do |key, value|
    puts "[*] #{key}: #{value}"
  end
end

#
# Main
#
if @dc.alive!
  puts "[+] Connected to #{@serverport}"

  puts
  puts '[+] Remote memcached stats:'
  puts

  stats

  found_slabs = slabs
  
  unless found_slabs.empty?
    puts
    puts '[+] Remote memcached key values:'
    puts

    values(found_slabs)
  else
    puts
    puts '[!] No slabs found.'
  end

  @dc.close
end
