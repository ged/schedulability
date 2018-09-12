#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

# SimpleCov test coverage reporting; enable this using the :coverage rake task
if ENV['COVERAGE']
	$stderr.puts "\n\n>>> Enabling coverage report.\n\n"
	require 'simplecov'
	SimpleCov.start do
		add_filter 'spec'
	end
end

require 'schedulability'
require 'loggability/spechelpers'


# Helpers specific to Schedulability specs
module Schedulability::SpecHelpers
end # module Schedulability::SpecHelpers


### Mock with RSpec
RSpec.configure do |c|
	c.run_all_when_everything_filtered = true
	c.filter_run :focus
	c.order = 'random'
	c.warnings = true

	c.mock_with( :rspec ) do |mock|
		mock.syntax = :expect
	end

	c.include( Loggability::SpecHelpers )
	c.include( Schedulability::SpecHelpers )
end

