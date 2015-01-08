#!/usr/bin/env ruby

# gem install typhoeus
# gem install nokogiri

require 'typhoeus'
require 'nokogiri'

nist_url   = 'http://web.nvd.nist.gov/view/vuln/detail?vulnId='
cve_hash   = {}
cve_output = ''


cves = File.open('cves.txt').read

cves.gsub!(/\r\n?/, "\n") # normalize EOL chars

cves.split("\n").each do |cve|
  puts "Getting CVSS for #{cve}..."
  doc        = Nokogiri::HTML(Typhoeus.get("#{nist_url}#{cve}").body)
  cvss_links = doc.css('#BodyPlaceHolder_cplPageContent_plcZones_lt_zoneCenter_VulnerabilityDetail_VulnFormView_VulnCvssPanel .row a')

  cve_hash[cve] = cvss_links[0].text
end

puts
puts

cve_hash = Hash[cve_hash.sort_by{|k, v| v}.reverse]

cve_hash.each_pair do |cve, score|
 cve_output << "#{cve} (CVSS:#{score}), "
end

puts cve_output
