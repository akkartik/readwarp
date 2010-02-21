require 'rubygems'
require 'active_support'

puts $ARGV[0].to_i.days.ago.strftime('%Y-%m-%d')
