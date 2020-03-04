# -*- ruby -*-
# frozen_string_literal: true
# vim: set nosta noet ts=4 sw=4:

require 'loggability'


# A mixin that provides scheduling to an including object.
module Schedulability
	extend Loggability

	# Package version constant
	VERSION = '0.5.0'

	# VCS revision
	REVISION = %q$Revision$


	# Loggability API -- set up a logger for Schedulability objects
	log_as :schedulability


	autoload :Schedule, 'schedulability/schedule'
	autoload :Parser, 'schedulability/parser'
	autoload :TimeRefinements, 'schedulability/mixins'

	autoload :Error, 'schedulability/exceptions'
	autoload :ParseError, 'schedulability/exceptions'
	autoload :RangeError, 'schedulability/exceptions'

end # module Schedulability

