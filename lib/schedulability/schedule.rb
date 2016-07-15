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
		positive, negative = Schedulability::Parser.extract_periods( expression )
		return new( positive, negative )
	end


	### Create a new Schedule using the specified +periods+.
	def initialize( positive_periods=[], negative_periods=[] )
		positive_periods ||= []
		negative_periods ||= []

		@positive_periods = positive_periods.flatten.uniq
		@positive_periods.freeze
		@negative_periods = negative_periods.flatten.uniq
		@negative_periods.freeze
	end


	# The periods that express which times are in the schedule
	attr_reader :positive_periods

	# The periods that express which times are *not* in the schedule
	attr_reader :negative_periods


	### Returns +true+ if the schedule doesn't have any time periods.
	def empty?
		return self.positive_periods.empty? && self.negative_periods.empty?
	end


	### Returns +true+ if the current time is within one of the Schedule's periods.
	def now?
		return self.include?( Time.now )
	end


	### Returns +true+ if the specified +time+ is in the schedule.
	def include?( time )
		time_obj = if time.respond_to?( :to_time )
				time.to_time
			else
				time_obj = Time.parse( time.to_s )
				self.log.debug "Parsed %p to time %p" % [ time, time_obj ]
				time_obj
			end

		return ! self.negative_periods_include?( time_obj ) &&
			self.positive_periods_include?( time_obj )
	 end


	 ### Returns +true+ if any of the schedule's positive periods include the
	 ### specified +time+.
	 def positive_periods_include?( time )
		return self.positive_periods.empty? ||
			find_matching_period_for( time, self.positive_periods )
	 end


	 ### Returns +true+ if any of the schedule's negative periods include the
	 ### specified +time+.
	 def negative_periods_include?( time )
		return find_matching_period_for( time, self.negative_periods )
	end


	### Returns +true+ if the schedule has any times which overlap those of +other_schedule+.
	def overlaps?( other_schedule )
		return ! self.exclusive?( other_schedule )
	end
	alias_method :overlaps_with?, :overlaps?


	### Returns +true+ if the schedule does not have any times which overlap those
	### of +other_schedule+.
	def exclusive?( other_schedule )
		return ( self & other_schedule ).empty?
	end
	alias_method :exclusive_of?, :exclusive?
	alias_method :is_exclusive_of?, :exclusive?


	### Returns +true+ if the time periods for +other_schedule+ are the same as those for the
	### receiver.
	def ==( other_schedule )
		other_schedule.is_a?( self.class ) &&
			self.positive_periods.all? {|period| other_schedule.positive_periods.include?(period) } &&
			other_schedule.positive_periods.all? {|period| self.positive_periods.include?(period) } &&
			self.negative_periods.all? {|period| other_schedule.negative_periods.include?(period) } &&
			other_schedule.negative_periods.all? {|period| self.negative_periods.include?(period) }
	end


	### Return a new Schedulability::Schedule object that is the union of the receiver and
	### +other_schedule+.
	def |( other_schedule )
		positive = self.positive_periods + other_schedule.positive_periods
		negative = intersect_periods( self.negative_periods, other_schedule.negative_periods )

		return self.class.new( positive, negative )
	end
	alias_method :+, :|


	### Return a new Schedulability::Schedule object that is the intersection of the receiver and
	### +other_schedule+.
	def &( other_schedule )
		positive = intersect_periods( self.positive_periods, other_schedule.positive_periods )
		negative = self.negative_periods + other_schedule.negative_periods

		return self.class.new( positive, negative )
	end


	### Return a new Schedulability::Schedule object that inverts the positive and negative
	### period criteria.
	def ~@
		return self.class.new( self.negative_periods, self.positive_periods )
	end


	### Return a string from previously parsed Schedule period objects.
	def to_s
		str = Schedulability::Parser.stringify( self.positive_periods )
		unless self.negative_periods.empty?
			str << ", not %s" % [ Schedulability::Parser.stringify(self.negative_periods) ]
		end

		return str
	end


	#######
	private
	#######

	### Returns true if any of the specified +periods+ contains the specified +time+.
	def find_matching_period_for( time, periods )
		periods.any? do |period|
			period.all? do |scale, ranges|
				val = value_for_scale( time, scale )
				ranges.any? {|rng| rng.cover?(val) }
			end
		end
	end


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


	### Return the specified +periods+ exploded into integer arrays instead of Ranges.
	def explode( periods )
		return periods.map do |per|
			per.each_with_object({}) do |(scale,ranges), hash|
				hash[ scale ] = ranges.flat_map( &:to_a )
			end
		end
	end


	### Return the intelligent merge of the +left+ and +right+ period hashes, only retaining
	### values that exist on both sides.
	def intersect_periods( left, right )
		new_periods = []
		explode( left ).product( explode(right) ) do |p1, p2|
			new_period = {}
			common_scales = p1.keys & p2.keys

			# Keys exist on both sides, diff+merge identical values
			common_scales.each do |scale|
				vals = p1[ scale ] & p2[ scale ]
				new_period[ scale ] = Schedulability::Parser.coalesce_ranges( vals, scale )
			end
			next if new_period.values.any?( &:empty? )

			# Keys exist only on one side, sync between sides because
			# the other side is implicitly infinite.
			(p1.keys - common_scales).each do |scale|
				new_period[ scale ] = Schedulability::Parser.coalesce_ranges( p1[scale], scale )
			end
			(p2.keys - common_scales).each do |scale|
				new_period[ scale ] = Schedulability::Parser.coalesce_ranges( p2[scale], scale )
			end

			new_periods << new_period
		end

		return new_periods
	end


end # class Schedulability::Schedule
