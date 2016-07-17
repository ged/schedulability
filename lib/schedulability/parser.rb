# -*- ruby -*-
#encoding: utf-8

require 'loggability'
require 'schedulability' unless defined?( Schedulability )


# A collection of parsing functions for Schedulability schedule syntax.
module Schedulability::Parser
	extend Loggability


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

	# Scales that are parsed with exclusive end values.
	EXCLUSIVE_RANGED_SCALES = %i[ hour hr minute min second sec ]

	# The Regexp for matching value periods
	PERIOD_PATTERN = %r:
		(\A|\G\s+) # beginning of the string or the end of the last match
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

	# Downcased month-name Arrays
	ABBR_MONTHNAMES = Date::ABBR_MONTHNAMES.map {|val| val && val.downcase }
	MONTHNAMES = Date::MONTHNAMES.map {|val| val && val.downcase }


	###############
	module_function
	###############

	### Normalize an array of parsed periods into a human readable string.
	def stringify( periods )
		strings = []
		periods.each do |period|
			period_string = []
			period.sort_by{|k, v| k}.each do |scale, ranges|
				range_string = ""
				range_string << "%s { " % [ scale.to_s ]

				range_strings = ranges.each_with_object( [] ).each do |range, acc|
					if range.min == range.max
						acc << range.min
					elsif range.exclude_end?
						acc << "%d-%d" % [ range.min, range.max + 1 ]
					else
						acc << "%d-%d" % [ range.min, range.max ]
					end
				end

				range_string << range_strings.join( ' ' ) << " }"
				period_string << range_string
			end
			strings << period_string.join( ' ' )
		end

		return strings.join( ', ' )
	end


	### Scan +expression+ for periods and return them in an Array.
	def extract_periods( expression )
		positive_periods = []
		negative_periods = []

		expression.strip.downcase.split( /\s*,\s*/ ).each do |subexpr|
			hash, negative = self.extract_period( subexpr )
			if negative
				negative_periods << hash
			else
				positive_periods << hash
			end
		end

		return positive_periods, negative_periods
	end


	### Return the specified period +expression+ as a Hash of Ranges keyed by scale.
	def extract_period( expression )
		hash = {}
		scanner = StringScanner.new( expression )

		negative = scanner.skip( /\s*(!|not |except )\s*/ )

		while scanner.scan( PERIOD_PATTERN )
			ranges = scanner[:ranges].strip
			scale = scanner[:scale]

			case scale
			when 'year',   'yr'
				hash[:yr] = self.extract_year_ranges( ranges )
			when 'month',  'mo'
				hash[:mo] = self.extract_month_ranges( ranges )
			when 'week',   'wk'
				hash[:wk] = self.extract_week_ranges( ranges )
			when 'yday',   'yd'
				hash[:yd] = self.extract_yday_ranges( ranges )
			when 'mday',   'md'
				hash[:md] = self.extract_mday_ranges( ranges )
			when 'wday',   'wd'
				hash[:wd] = self.extract_wday_ranges( ranges )
			when 'hour',   'hr'
				hash[:hr] = self.extract_hour_ranges( ranges )
			when 'minute', 'min'
				hash[:min] = self.extract_minute_ranges( ranges )
			when 'second', 'sec'
				hash[:sec] = self.extract_second_ranges( ranges )
			else
				# This should never happen
				raise ArgumentError, "Unhandled scale %p!" % [ scale ]
			end
		end

		unless scanner.eos?
			raise Schedulability::ParseError,
				"malformed schedule (at %d: %p)" % [ scanner.pos, scanner.rest ]
		end

		return hash, negative
	ensure
		scanner.terminate if scanner
	end


	### Return an Array of year integer Ranges for the specified +ranges+ expression.
	def extract_year_ranges( ranges )
		ranges = self.extract_ranges( :year, ranges, 2000, 9999 ) do |val|
			Integer( val )
		end

		if ranges.any? {|rng| rng.end == 9999 }
			raise Schedulability::ParseError, "no support for wrapped year ranges"
		end

		return ranges
	end


	### Return an Array of month Integer Ranges for the specified +ranges+ expression.
	def extract_month_ranges( ranges )
		return self.extract_ranges( :month, ranges, 0, MONTHNAMES.size - 1 ) do |val|
			self.map_integer_value( :month, val, [ABBR_MONTHNAMES, MONTHNAMES] )
		end
	end


	### Return an Array of week-of-month Integer Ranges for the specified +ranges+ expression.
	def extract_week_ranges( ranges )
		return self.extract_ranges( :week, ranges, 1, 5 ) do |val|
			Integer( strip_leading_zeros(val) )
		end
	end


	### Return an Array of day-of-year Integer Ranges for the specified +ranges+ expression.
	def extract_yday_ranges( ranges )
		return self.extract_ranges( :yday, ranges, 1, 366 ) do |val|
			Integer( strip_leading_zeros(val) )
		end
	end


	### Return an Array of day-of-month Integer Ranges for the specified +ranges+ expression.
	def extract_mday_ranges( ranges )
		return self.extract_ranges( :mday, ranges, 0, 31 ) do |val|
			Integer( strip_leading_zeros(val) )
		end
	end


	### Return an Array of weekday Integer Ranges for the specified +ranges+ expression.
	def extract_wday_ranges( ranges )
		return self.extract_ranges( :wday, ranges, 0, DAYNAMES.size - 1 ) do |val|
			self.map_integer_value( :wday, val, [ABBR_DAYNAMES, DAYNAMES] )
		end
	end


	### Return an Array of 24-hour Integer Ranges for the specified +ranges+ expression.
	def extract_hour_ranges( ranges )
		return self.extract_ranges( :hour, ranges, 0, 24 ) do |val|
			self.extract_hour_value( val )
		end
	end


	### Return an Array of Integer minute Ranges for the specified +ranges+ expression.
	def extract_minute_ranges( ranges )
		return self.extract_ranges( :minute, ranges, 0, 60 ) do |val|
			Integer( strip_leading_zeros(val) )
		end
	end


	### Return an Array of Integer second Ranges for the specified +ranges+ expression.
	def extract_second_ranges( ranges )
		return self.extract_ranges( :second, ranges, 0, 60 ) do |val|
			Integer( strip_leading_zeros(val) )
		end
	end


	### Return the integer equivalent of the specified +time_value+.
	def extract_hour_value( time_value )
		unless match = TIME_VALUE_PATTERN.match( time_value )
			raise Schedulability::ParseError, "invalid hour range: %p" % [ time_value ]
		end

		hour, qualifier = match[:hour], match[:qualifier]
		hour = hour.to_i

		if qualifier
			raise Schedulability::RangeError, "invalid hour value: %p" % [ time_value ] if
				hour > 12
			hour += 12 if qualifier == 'pm' && hour < 12
		else
			raise Schedulability::RangeError, "invalid hour value: %p" % [ time_value ] if
				hour > 24
			hour = 24 if hour.zero?
		end

		return hour
	end


	### Extract an Array of Ranges from the specified +ranges+ string using the given
	### +index_arrays+ for non-numeric values. Construct the Ranges with the given
	### +minval+/+maxval+ range boundaries.
	def extract_ranges( scale, ranges, minval, maxval )
		exclude_end = EXCLUSIVE_RANGED_SCALES.include?( scale )
		valid_range = Range.new( minval, maxval, exclude_end )

		ints = ranges.split( /(?<!-)\s+(?!-)/ ).flat_map do |range|
			min, max = range.split( /\s*-\s*/, 2 )

			min = yield( min )
			raise Schedulability::ParseError, "invalid %s value: %p" % [ scale, min ] unless
				valid_range.cover?( min )
			next [ min ] unless max

			max = yield( max )
			raise Schedulability::ParseError, "invalid %s value: %p" % [ scale, max ] unless
				valid_range.cover?( max )

			if min > max
				Range.new( minval, max, exclude_end ).to_a +
					Range.new( min, maxval, false ).to_a
			else
				Range.new( min, max, exclude_end ).to_a
			end
		end

		return self.coalesce_ranges( ints, scale )
	end


	### Coalese an Array of non-contiguous Range objects from the specified +ints+ for +scale+.
	def coalesce_ranges( ints, scale )
		exclude_end = EXCLUSIVE_RANGED_SCALES.include?( scale )
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
	def map_integer_value( scale, value, index_arrays )
		return Integer( value ) if value =~ /\A\d+\z/

		unless index = index_arrays.inject( nil ) {|res, ary| res || ary.index(value) }
			expected = "expected one of: %s, %d-%d" % [
				index_arrays.flatten.compact.flatten.join( ', ' ),
				index_arrays.first.index {|val| val },
				index_arrays.first.size - 1
			]
			raise Schedulability::ParseError, "invalid %s value: %p (%s)" %
				[ scale, value, expected ]
		end

		return index
	end


	### Return a copy of the specified +val+ with any leading zeros stripped.
	### If the resulting string is empty, return "0".
	def strip_leading_zeros( val )
		return val.sub( /\A0+(?!$)/, '' )
	end

end # module Schedulability::Parser

