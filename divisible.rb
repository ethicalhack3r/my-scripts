#!/usr/bin/env ruby

#
# Works out what the input integer is divisible by, useful for padbuster.
#

@input = ARGV[0]

def divisible?(i)
  (@input.to_i % i).zero?
end

(2...@input.to_i).each_with_index do |i|
	puts "#{@input} is divisible by #{i}" if divisible?(i)
end
