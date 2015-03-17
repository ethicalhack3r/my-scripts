#!/usr/bin/env ruby

#
# Obtains the latest version number from a list of Drupal modules.
# Useful when you want to figure out if drupal modules are outdates or not.
#

require 'typhoeus'
require 'nokogiri'

modules    = File.open(ARGV.join).read.split("\n")
module_url = 'https://www.drupal.org/project/'

modules.each do |drupal_module|
  response = Typhoeus.get(module_url + drupal_module)
  doc      = Nokogiri::HTML(response.body)

  latest_version = doc.css('.views-field-field-release-version a')[0].text

  puts "#{drupal_module} #{latest_version}"
end

