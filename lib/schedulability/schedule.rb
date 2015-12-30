# -*- ruby -*-
#encoding: utf-8

require 'strscan'

require 'loggability'
require 'schedulability' unless defined?( Schedulability )
require 'schedulability/exceptions'


# A schedule object representing one or more abstract ranges of times.
class Schedulability::Schedule
	extend Loggability


	# Schedulability API -- Log to the Schedulability logger
	log_to :schedulability


	### Parse one or more periods from the specified +expression+ and return a Schedule
	### created with them.
	def self::parse( expression )
		periods = Schedulability::Parser.extract_periods( expression )
		return new( *periods )
	end


	### Create a new Schedule using the specified +periods+.
	def initialize( *periods )
		@periods = periods
	end


	# The object's periods
	attr_reader :periods


	### Returns +true+ if the schedule doesn't have any time periods.
	def empty?
		return @periods.empty?
	end


	### Returns +true+ if the current time is within one of the Schedule's periods.
	def now?
		return self.include?( Time.now )
	end


	### Returns +true+ if the specified +time+ is within one of the scheduled periods.
	def include?( time )
		time_obj = if time.respond_to?( :to_time )
				time.to_time
			else
				time_obj = Time.parse( time.to_s )
				self.log.debug "Parsed %p to time %p" % [ time, time_obj ]
				time_obj
			end

		@periods.any? do |period|
			period.all? do |scale, ranges|
				val = value_for_scale( time_obj, scale )
				self.log.debug "Do any of %p cover the %p %d?" % [ ranges, scale, val ]
				ranges.any? {|rng| rng.cover?(val) }
			end
		end
	end



	#######
	private
	#######

	### Return the appropriate numeric value for the specified +scale+ from the
	### given +time+.
	def value_for_scale( time, scale )
		case scale
		when :mo
			return time.mon
		when :md
			return time.day
		when :wd
			return time.wday
		when :hr
			return time.hour
		when :min
			return time.min
		when :sec
			return time.sec
		when :yd
			return time.yday
		when :wk
			return ( time.day / 7.0 ).ceil
		when :yr
			self.log.debug "Year match: %p" % [ time.year ]
			return time.year
		else
			# If this happens, it's likely a bug in the parser.
			raise ScriptError, "unknown scale %p" % [ scale ]
		end
	end


end # class Schedulability::Schedule
