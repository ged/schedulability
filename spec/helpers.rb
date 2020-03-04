#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:
# frozen_string_literal: true

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
RSpec.configure do |config|

	config.mock_with( :rspec ) do |mock|
		mock.syntax = :expect
	end

	config.disable_monkey_patching!
	config.example_status_persistence_file_path = "spec/.status"
	config.filter_run :focus
	config.filter_run_when_matching :focus
	config.order = :random
	config.profile_examples = 5
	config.run_all_when_everything_filtered = true
	config.shared_context_metadata_behavior = :apply_to_host_groups
	config.warnings = true

	config.include( Loggability::SpecHelpers )
	config.include( Schedulability::SpecHelpers )
end

