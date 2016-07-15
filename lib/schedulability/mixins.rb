# -*- ruby -*-
#encoding: utf-8

require 'schedulability' unless defined?( Schedulability )

module Schedulability

	# Functions for time calculations
	module TimeFunctions

		###############
		module_function
		###############

		### Calculate the (approximate) number of seconds that are in +count+ of the
		### given +unit+ of time.
		###
		def calculate_seconds( count, unit )
			return case unit
			when :seconds, :second
				count
			when :minutes, :minute
				count * 60
			when :hours, :hour
				count * 3600
			when :days, :day
				count * 86400
			when :weeks, :week
				count * 604800
			when :fortnights, :fortnight
				count * 1209600
			when :months, :month
				count * 2592000
			when :years, :year
				count * 31557600
			else
				raise ArgumentError, "don't know how to calculate seconds in a %p" % [ unit ]
			end
		end
	end # module TimeFunctions


	# Refinements to Numeric to add time-related convenience methods
	module TimeRefinements
		refine Numeric do

			### Number of seconds (returns receiver unmodified)
			def seconds
				return self
			end
			alias_method :second, :seconds

			### Returns number of seconds in <receiver> minutes
			def minutes
				return TimeFunctions.calculate_seconds( self, :minutes )
			end
			alias_method :minute, :minutes

			### Returns the number of seconds in <receiver> hours
			def hours
				return TimeFunctions.calculate_seconds( self, :hours )
			end
			alias_method :hour, :hours

			### Returns the number of seconds in <receiver> days
			def days
				return TimeFunctions.calculate_seconds( self, :day )
			end
			alias_method :day, :days

			### Return the number of seconds in <receiver> weeks
			def weeks
				return TimeFunctions.calculate_seconds( self, :weeks )
			end
			alias_method :week, :weeks

			### Returns the number of seconds in <receiver> fortnights
			def fortnights
				return TimeFunctions.calculate_seconds( self, :fortnights )
			end
			alias_method :fortnight, :fortnights

			### Returns the number of seconds in <receiver> months (approximate)
			def months
				return TimeFunctions.calculate_seconds( self, :months )
			end
			alias_method :month, :months

			### Returns the number of seconds in <receiver> years (approximate)
			def years
				return TimeFunctions.calculate_seconds( self, :years )
			end
			alias_method :year, :years


			### Returns the Time <receiver> number of seconds before the
			### specified +time+. E.g., 2.hours.before( header.expiration )
			def before( time )
				return time - self
			end


			### Returns the Time <receiver> number of seconds ago. (e.g.,
			### expiration > 2.hours.ago )
			def ago
				return self.before( ::Time.now )
			end


			### Returns the Time <receiver> number of seconds after the given +time+.
			### E.g., 10.minutes.after( header.expiration )
			def after( time )
				return time + self
			end


			### Return a new Time <receiver> number of seconds from now.
			def from_now
				return self.after( ::Time.now )
			end

		end # refine Numeric


		refine Time do

			# Approximate Time Constants (in seconds)
			MINUTES = 60
			HOURS   = 60  * MINUTES
			DAYS    = 24  * HOURS
			WEEKS   = 7   * DAYS
			MONTHS  = 30  * DAYS
			YEARS   = 365.25 * DAYS


			### Returns +true+ if the receiver is a Time in the future.
			def future?
				return self > Time.now
			end


			### Returns +true+ if the receiver is a Time in the past.
			def past?
				return self < Time.now
			end


			### Return a description of the receiving Time object in relation to the current
			### time.
			###
			### Example:
			###
			###    "Saved %s ago." % object.updated_at.as_delta
			def as_delta
				now = Time.now
				if now > self
					seconds = now - self
					return "%s ago" % [ timeperiod(seconds) ]
				else
					seconds = self - now
					return "%s from now" % [ timeperiod(seconds) ]
				end
			end


			### Return a description of +seconds+ as the nearest whole unit of time.
			def timeperiod( seconds )
				return case
					when seconds < MINUTES - 5
						'less than a minute'
					when seconds < 50 * MINUTES
						if seconds <= 89
							"a minute"
						else
							"%d minutes" % [ (seconds.to_f / MINUTES).ceil ]
						end
					when seconds < 90 * MINUTES
						'about an hour'
					when seconds < 18 * HOURS
						"%d hours" % [ (seconds.to_f / HOURS).ceil ]
					when seconds < 30 * HOURS
						'about a day'
					when seconds < WEEKS
						"%d days" % [ (seconds.to_f / DAYS).ceil ]
					when seconds < 2 * WEEKS
						'about a week'
					when seconds < 3 * MONTHS
						"%d weeks" % [ (seconds.to_f / WEEKS).round ]
					when seconds < 18 * MONTHS
						"%d months" % [ (seconds.to_f / MONTHS).ceil ]
					else
						"%d years" % [ (seconds.to_f / YEARS).ceil ]
					end
			end

		end # refine Time

	end # module TimeRefinements

end # module Schedulability

