#!/usr/bin/ruby

if ARGV.length < 3
  puts "Usage: ruby update-identities.rb identity source destination"
  exit
end

identity = ARGV.shift
source = ARGV.shift
destination = ARGV.shift

fullIdentity = nil

identities = %x{security find-identity -p codesigning -v | grep '#{identity}'}
re = /\s+\d+\)\s[\d\w]+\s\"(.*)\"/
if results = identities.match(re)
	puts "Found: #{results[1]}"
	fullIdentity = results[1]
else
	puts "No identity matched: #{identity}"
	exit(1)
end

%x{sed "s/BC_CODE_SIGNING_IDENTITY/#{fullIdentity}/" "#{source}" > "#{destination}"}
puts "Saved #{destination}"
