#!/usr/bin/env ruby

require 'typhoeus'
require 'json'
require 'uri'
require 'digest/md5'

# https://raw.githubusercontent.com/gwillem/magento-version-identification/master/version_hashes.json

target  = ARGV[0]
hashes  = JSON.parse(File.open('version_hashes.json').read)
hydra   = Typhoeus::Hydra.hydra

hashes.each do |hash|
  file    = hash[0]
  url     = URI.join(target, file).to_s
  request = Typhoeus::Request.new(url, followlocation: true)
  hashes  = hash[1].keys

  hydra.queue(request)

  request.on_complete do |response|
    if response.success?
      response_hash = Digest::MD5.hexdigest(response.body)

      if hash[1].keys.include? response_hash
        puts "[+] Magento version detected as #{hash[1][response_hash]} from #{url} using hash #{response_hash}"
      end
    elsif response.timed_out?
      # aw hell no
    elsif response.code == 0
      # Could not get an http response, something's wrong.
    else
      # Received a non-successful http response.
    end
  end
end

hydra.run
