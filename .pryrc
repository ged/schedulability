#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:

BEGIN {
    require 'pathname'
	$LOAD_PATH.unshift( Pathname.new( __FILE__ ).dirname + 'lib' )
}

begin
	require 'schedulability'
rescue Exception => err
	$stderr.puts "Schedulability failed to load: %p: %s" % [ err.class, err.message ]
	$stderr.puts( err.backtrace )
end

