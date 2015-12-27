# -*- ruby -*-
#encoding: utf-8

require 'loggability'
require 'schedulability' unless defined?( Schedulability )
require 'schedulability/exceptions'

# A schedule object representing one or more abstract ranges of times.
class Schedulability::Schedule
	extend Loggability


	# Schedulability API -- Log to the Schedulability logger
	log_to :schedulability


	# A Regexp that will match valid period scale codes
	VALID_SCALES = Regexp.union(%w[
		year   yr
		month  mo
		week   wk
		yday   yd
		mday   md
		wday   wd
		hour   hr
		minute min
		second sec
	])

	# The Regexp for matching value periods
	PERIOD_PATTERN = %r:
		(?<scale> #{VALID_SCALES} )
		s? # Optional plural sugar
		\s*
		\{
			(?<ranges>.*?)
		\}
	:ix

	# Pattern for matching +hour+-scale values
	TIME_VALUE_PATTERN = /\A(?<hour>\d+)(?<qualifier>am|pm|noon)?\z/i

	# Downcased day-name Arrays
	ABBR_DAYNAMES = Date::ABBR_DAYNAMES.map( &:downcase )
	DAYNAMES = Date::DAYNAMES.map( &:downcase )


	### Parse one or more periods from the specified +expression+ and return a Schedule
	### created with them.
	def self::parse( expression )
		periods = self.extract_periods( expression )
		return new( *periods )
	end


	### Scan +expression+ for periods and return them in an Array.
	def self::extract_periods( expression )
		return expression.strip.downcase.split( /\s*,\s*/ ).map do |subexpr|
			self.extract_period( subexpr )
		end
	end


	### Return the specified period +expression+ as a Hash of Ranges keyed by scale.
	def self::extract_period( expression )
		hash = {}
		expression.scan( PERIOD_PATTERN ) do |scale, ranges|
			case scale
			# when 'year',   'yr'
			# 	hash[:yr] = self.extract_year_ranges( ranges )
			# when 'month',  'mo'
			# 	hash[:mo] = self.extract_month_ranges( ranges )
			# when 'week',   'wk'
			# 	hash[:wk] = self.extract_week_ranges( ranges )
			# when 'yday',   'yd'
			# 	hash[:yd] = self.extract_yday_ranges( ranges )
			# when 'mday',   'md'
			# 	hash[:md] = self.extract_mday_ranges( ranges )
			when 'wday',   'wd'
				hash[:wd] = self.extract_wday_ranges( ranges )
			when 'hour',   'hr'
				hash[:hr] = self.extract_hour_ranges( ranges )
			# when 'minute', 'min'
			# 	hash[:min] = self.extract_minute_ranges( ranges )
			# when 'second', 'sec'
			# 	hash[:sec] = self.extract_second_ranges( ranges )
			else
				raise ArgumentError, "Unhandled scale %p!" % [ scale ]
			end
		end

		return hash
	end


	### Return an Array of weekday Integer Ranges for the specified +ranges+ expression.
	def self::extract_wday_ranges( ranges )
		return self.extract_ranges( ranges, 0, DAYNAMES.size - 1, false ) do |val|
			self.map_integer_value( val, [ABBR_DAYNAMES, DAYNAMES] )
		end
	end


	### Return an Array of 24-hour Integer Ranges for the specified +ranges+ expression.
	def self::extract_hour_ranges( ranges )
		return self.extract_ranges( ranges, 0, 24, true ) do |val|
			self.extract_hour_value( val )
		end
	end


	### Return the integer equivalent of the specified +time_value+.
	def self::extract_hour_value( time_value )
		unless match = TIME_VALUE_PATTERN.match( time_value )
			raise Schedulability::ParseError, "invalid hour range value: %p" % [ time_value ]
		end

		hour, qualifier = match[:hour], match[:qualifier]
		hour = hour.to_i

		if qualifier
			raise Schedulability::RangeError, "invalid time range: %p" % [ time_value ] if
				hour > 12
			hour += 12 if qualifier == 'pm'
		else
			raise Schedulability::RangeError, "invalid time range: %p" % [ time_value ] if
				hour > 24
			hour = 24 if hour.zero?
		end

		return hour
	end


	### Extract an Array of Ranges from the specified +ranges+ string using the given
	### +index_arrays+ for non-numeric values. Construct the Ranges with the given
	### +exclude_end+ and +minval+/+maxval+ range boundaries.
	def self::extract_ranges( ranges, minval, maxval, exclude_end=true )
		ints = ranges.split( /(?<!-)\s+(?!-)/ ).flat_map do |range|
			min, max = range.split( /\s*-\s*/, 2 )
			self.log.debug "Min = %p, max = %p" % [ min, max ]

			min = yield( min )
			next [ min ] unless max

			max = yield( max )
			self.log.debug "Parsed min = %p, max = %p" % [ min, max ]
			if min > max
				self.log.debug "wrapped: %d-%d and %d-%d" % [ minval, max, min, maxval ]
				Range.new( minval, max, exclude_end ).to_a +
					Range.new( min, maxval, exclude_end ).to_a
			else
				Range.new( min, max, exclude_end ).to_a
			end
		end

		return self.coalesce_ranges( ints, exclude_end )
	end


	### Coalese an Array of non-contiguous Range objects from the specified +ints+.
	def self::coalesce_ranges( ints, exclude_end=false )
		self.log.debug "Coalescing %d ints to Ranges (%p)" % [ ints.size, ints ]
		ints.flatten!
		return [] if ints.empty?

		prev = ints[0]
		range_ints = ints.sort.slice_before do |v|
			prev, prev2 = v, prev
			prev2.succ != v
		end

		return range_ints.map do |values|
			last_val = values.last
			last_val += 1 if exclude_end
			Range.new( values.first, last_val, exclude_end )
		end
	end


	### Map a +value+ from a period's range to an Integer, using the specified +index_arrays+
	### if it doesn't look like an integer string.
	def self::map_integer_value( value, index_arrays )
		return Integer( value ) if value =~ /\A\d+\z/

		unless index = index_arrays.inject( nil ) {|res, ary| res || ary.index(value) }
			expected = "expected one of: %s, %d-%d" % [
				index_arrays.flatten.join( ', ' ),
				index_arrays.first.index {|val| val },
				index_arrays.first.size - 1
			]
			raise Schedulability::ParseError, "invalid range value: #{expected}"
		end

		return index
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
		time = Time.parse( time.to_s ) unless time.respond_to?( :to_time )
		time = time.to_time

		@periods.any? do |period|
			period.all? do |scale, ranges|
				val = value_for_scale( time, scale )
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
		when :wd
			return time.wday
		when :hr
			return time.hour
		else
			raise "unknown scale"
		end
	end

end # class Schedulability::Schedule
