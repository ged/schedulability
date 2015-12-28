# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'loggability'


# A mixin that provides scheduling to an including object.
module Schedulability
	extend Loggability

	# Package version constant
	VERSION = '0.11.0'

	# VCS revision
	REVISION = %q$Revision$


	# Loggability API -- set up a logger for Schedulability objects
	log_as :schedulability


	autoload :Schedule, 'schedulability/schedule'
	autoload :TimeRefinements, 'schedulability/mixins'

end # module Schedulability

