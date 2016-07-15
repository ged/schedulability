#!/usr/bin/env rspec -cfd

require_relative '../helpers'

require 'time'
require 'timecop'
require 'schedulability/schedule'
require 'schedulability/mixins'


using Schedulability::TimeRefinements

describe Schedulability::Schedule do

	before( :all ) do
		@actual_zone = ENV['TZ']
		ENV['TZ'] = 'GMT'
	end

	after( :all ) do
		ENV['TZ'] = @actual_zone
	end


	let( :testing_time ) { Time.iso8601('2015-12-15T12:00:00-00:00') }


	RSpec::Matchers.define( :overlap ) do |other|
		match do |schedule|
			schedule.overlaps?( other )
		end
	end


	context "with no periods" do

		let( :schedule ) { described_class.new }


		it "is empty" do
			expect( schedule ).to be_empty
		end


		it "is always 'now'" do
			Timecop.freeze( testing_time ) do
				expect( schedule ).to be_now
			end
		end


		it "includes every time" do
			expect( schedule ).to include( testing_time )
		end


		it "is equal to other empty schedules" do
			expect( schedule ).to be == described_class.new
		end


		it "is not equal to any other non-empty schedules" do
			expect( schedule ).to_not be == described_class.new( md: 10..10 )
		end

	end


	context "with one simple time period" do

		let( :schedule ) { described_class.parse("wd {Mon-Fri}") }


		it "isn't empty" do
			expect( schedule ).to_not be_empty
		end


		it "includes the current time if it's within the period" do
			Timecop.freeze( testing_time ) do
				expect( schedule ).to be_now
			end
		end


		it "includes a particular time within its period" do
			expect( schedule ).to include( testing_time )
		end


		it "doesn't include a time outside of its period" do
			expect( schedule ).to_not include( 'Tue Dec 13 12:00:00 2015' )
		end


		it "is equal to another schedule with the same period" do
			expect( schedule ).to be == described_class.parse( 'wd {Mon Tue Wed Thu Fri}' )
		end


		it "is not equal to another schedule if it doesn't have the same time periods" do
			expect( schedule ).to_not be == described_class.parse( 'wd {Mon-Sat}' )
			expect( schedule ).to_not be == described_class.parse( 'wd {Mon-Thu}' )
			expect( schedule ).to_not be == described_class.parse( 'wd {Mon-Fri} hour {6am-8am}' )
		end

	end


	context "with one time period with multiple scales" do

		let( :schedule ) { described_class.parse("wd {Sun Tue} hr {8am-4pm}") }


		it "isn't empty" do
			expect( schedule ).to_not be_empty
		end


		it "includes the current time if both scales match" do
			Timecop.freeze( testing_time ) do
				expect( schedule ).to be_now
			end
		end


		it "includes a particular time within its period" do
			expect( schedule ).to include( 'Tue Dec 15 12:00:00 2015' )
		end


		it "doesn't include a time outside of its period" do
			expect( schedule ).to_not include( 'Tue Dec 15 17:00:00 2015' )
		end

	end


	context "with multiple time periods" do

		let( :schedule ) do
			described_class.parse( "wd {Mon Wed Fri} hr {8am-4pm}, wd {Tue Thu} hr {9am-5pm}" )
		end


		it "isn't empty" do
			expect( schedule ).to_not be_empty
		end


		it "includes the current time if all scales of one of its periods match" do
			expect( schedule ).to include( 'Tue Dec 15 12:00:00 2015' )
			expect( schedule ).to include( 'Wed Dec 16 12:00:00 2015' )
		end


		it "doesn't include a time outside of all of its periods" do
			expect( schedule ).to_not include( 'Tue Dec 15  8:00:00 2015' )
			expect( schedule ).to_not include( 'Wed Dec 16 17:00:00 2015' )
			expect( schedule ).to_not include( 'Sat Dec 19 12:00:00 2015' )
		end


		it "respects negations" do
			schedule = described_class.
				parse( "wd {Mon Wed Fri} hr {8am-4pm}, wd {Tue Thu} hr {9am-5pm}, not hour { 3pm }" )
			expect( schedule ).to include( 'Tue Dec 15 12:00:00 2015' )
			expect( schedule ).to include( 'Wed Dec 16 12:00:00 2015' )
			expect( schedule ).to_not include( 'Wed Dec 16 15:05:00 2015' )
		end


		it "can be stringified" do
			schedule = described_class.
				parse( "wd {Mon Wed Fri} hr {8am-4pm}, wd {Tue Thu} hr {9am-5pm}, not hour { 3pm }" )
			expect( schedule.to_s ).to eq( "hr { 8-16 } wd { 1 3 5 }, hr { 9-17 } wd { 2 4 }, not hr { 15 }" )
		end
	end


	describe "period parsing" do

		it "matches single second values only during that second of every minute" do
			schedule = described_class.parse( "sec {18}" )
			time = Time.iso8601( '2015-12-15T12:00:18-00:00' )

			expect( schedule ).to_not include( time - 2.seconds )
			expect( schedule ).to_not include( time - 1.second )
			expect( schedule ).to include( time )
			expect( schedule ).to_not include( time + 1.second )
			expect( schedule ).to_not include( time + 2.seconds )
		end


		it "matches negated single second values during every other second of every minute" do
			schedule = described_class.parse( "except sec {18}" )
			time = Time.iso8601( '2015-12-15T12:00:18-00:00' )

			expect( schedule ).to include( time - 2.seconds )
			expect( schedule ).to include( time - 1.second )
			expect( schedule ).to_not include( time )
			expect( schedule ).to include( time + 1.second )
			expect( schedule ).to include( time + 2.seconds )
		end


		it "matches second range values as multi-second exclusive ranges" do
			schedule = described_class.parse( "sec {10-20}" )
			time = Time.iso8601( '2015-12-15T12:00:10-00:00' )

			expect( schedule ).to_not include( time - 2.seconds )
			expect( schedule ).to_not include( time - 1.second )
			expect( schedule ).to include( time )
			expect( schedule ).to include( time + 1.second )
			expect( schedule ).to include( time + 9.seconds )
			expect( schedule ).to_not include( time + 10.seconds )
		end


		it "matches wrapped second range values as two ranges covering the upper and lower parts" do
			schedule = described_class.parse( "sec {45-15}" )
			time = Time.iso8601( '2015-12-15T12:00:45-00:00' )

			expect( schedule ).to_not include( time - 2.seconds )
			expect( schedule ).to_not include( time - 1.second )
			expect( schedule ).to include( time )
			expect( schedule ).to include( time + 1.second )
			expect( schedule ).to include( time + 14.seconds )
			expect( schedule ).to include( time + 15.seconds )
			expect( schedule ).to include( time + 20.seconds )
			expect( schedule ).to include( time + 29.seconds )
			expect( schedule ).to_not include( time + 30.seconds )
		end


		it "matches single minute values as a 60-second exclusive range" do
			schedule = described_class.parse( "min {28}" )
			time = Time.iso8601( '2015-12-15T12:28:00-00:00' )

			expect( schedule ).to_not include( time - 15.seconds )
			expect( schedule ).to_not include( time - 1.second )
			expect( schedule ).to include( time )
			expect( schedule ).to include( time + 38.seconds )
			expect( schedule ).to include( time + 59.seconds )
			expect( schedule ).to_not include( time + 1.minute )
			expect( schedule ).to_not include( time + 2.minutes )
		end


		it "matches minute range values as multi-minute exclusive ranges" do
			schedule = described_class.parse( "min {25-35}" )
			time = Time.iso8601( '2015-12-15T12:25:00-00:00' )

			expect( schedule ).to_not include( time - 2.minutes )
			expect( schedule ).to_not include( time - 1.second )
			expect( schedule ).to include( time )
			expect( schedule ).to include( time + 1.minute )
			expect( schedule ).to include( time + 9.minutes )
			expect( schedule ).to include( time + 9.minutes + 59.seconds )
			expect( schedule ).to_not include( time + 10.minutes )
		end


		it "matches wrapped minute range values as two ranges covering the upper and lower parts" do
			schedule = described_class.parse( "min {50-15}" )
			time = Time.iso8601( '2015-12-15T12:50:00-00:00' )

			expect( schedule ).to_not include( time - 1.minute )
			expect( schedule ).to_not include( time - 1.second )
			expect( schedule ).to include( time )
			expect( schedule ).to include( time + 1.second )
			expect( schedule ).to include( time + 1.minute )
			expect( schedule ).to include( time + 9.minutes )
			expect( schedule ).to include( time + 9.minutes + 59.seconds )
			expect( schedule ).to include( time + 10.minutes )
			expect( schedule ).to include( time + 20.minutes )
			expect( schedule ).to include( time + 24.minutes )
			expect( schedule ).to include( time + 24.minutes + 59.seconds )
			expect( schedule ).to_not include( time + 25.minutes )
		end


		it "matches single hour values as a 3600-second exclusive range" do
			schedule = described_class.parse( "hr {8}" )
			time = Time.iso8601( '2015-12-15T08:00:00-00:00' )

			expect( schedule ).to_not include( time - 1 )
			expect( schedule ).to include( time )
			expect( schedule ).to include( time + 1.minute )
			expect( schedule ).to include( time + 20.minutes )
			expect( schedule ).to include( time + (1.hour - 1.minute) )
			expect( schedule ).to_not include( time + 1.hour )
			expect( schedule ).to_not include( time + 3.hours )
		end


		it "matches hour range values as multi-hour exclusive ranges" do
			schedule = described_class.parse( "hr {9am-5pm}" )
			time = Time.iso8601( '2015-12-15T09:00:00-00:00' )

			expect( schedule ).to_not include( time - 12.hours )
			expect( schedule ).to_not include( time - 10.minutes )
			expect( schedule ).to_not include( time - 1.second )
			expect( schedule ).to include( time )
			expect( schedule ).to include( time + 1.minute )
			expect( schedule ).to include( time + 1.hour )
			expect( schedule ).to include( time + 7.hours )
			expect( schedule ).to include( time + (8.hours - 1.second) )
			expect( schedule ).to_not include( time + 8.hours )
		end


		it "matches wrapped hour range values as two ranges covering the upper and lower parts" do
			schedule = described_class.parse( "hr {5pm-9am}" )
			time = Time.iso8601( '2015-12-15T17:00:00-00:00' )

			expect( schedule ).to_not include( time - 1.hour )
			expect( schedule ).to_not include( time - 1.second )
			expect( schedule ).to include( time )
			expect( schedule ).to include( time + 1.second )
			expect( schedule ).to include( time + 1.minute )
			expect( schedule ).to include( time + 10.minutes )
			expect( schedule ).to include( time + 2.hours )
			expect( schedule ).to include( time + (7.hours - 1.second) )
			expect( schedule ).to include( time + 7.hours )
			expect( schedule ).to include( time + 12.hours )
			expect( schedule ).to include( time + (16.hours - 1.second) )
			expect( schedule ).to include( time + 24.hours )
			expect( schedule ).to_not include( time + (24.hours - 1.second) )
			expect( schedule ).to_not include( time + 16.hours )
			expect( schedule ).to_not include( time + 18.hours )
		end


		it "handles 12pm correctly" do
			schedule = described_class.parse( "hr {12pm}" )
			time = Time.iso8601( '2015-12-15T12:00:00-00:00' )

			expect( schedule ).to_not include( time - 1 )
			expect( schedule ).to include( time )
			expect( schedule ).to include( time + 1.minute )
			expect( schedule ).to include( time + 20.minutes )
			expect( schedule ).to include( time + (1.hour - 1.minute) )
			expect( schedule ).to_not include( time + 1.hour )
			expect( schedule ).to_not include( time + 3.hours )
		end


		it "matches single day number values as a 86400-second exclusive range" do
			schedule = described_class.parse( "md {11}" )

			expect( schedule ).to_not include( '2014-06-10T23:00:00-00:00' )
			expect( schedule ).to_not include( '2014-06-10T23:59:59-00:00' )
			expect( schedule ).to include( '2014-06-11T00:00:00-00:00' )
			expect( schedule ).to include( '2014-06-11T00:01:00-00:00' )
			expect( schedule ).to include( '2014-06-11T01:00:00-00:00' )
			expect( schedule ).to include( '2014-06-11T12:00:00-00:00' )
			expect( schedule ).to include( '2014-06-11T23:59:59-00:00' )
			expect( schedule ).to_not include( '2014-06-12T00:00:00-00:00' )
			expect( schedule ).to_not include( '2014-06-12T02:00:00-00:00' )
		end


		it "matches day number range values as multi-day inclusive ranges" do
			schedule = described_class.parse( "md {13-15}" )

			expect( schedule ).to_not include( '2015-12-12T23:59:59:00:00-00:00' )
			expect( schedule ).to include( '2015-12-13T00:00:00-00:00' )
			expect( schedule ).to include( '2015-12-14T00:00:00-00:00' )
			expect( schedule ).to include( '2015-12-15T00:00:00-00:00' )
			expect( schedule ).to include( '2015-12-15T23:59:59-00:00' )
			expect( schedule ).to_not include( '2015-12-16T00:00:00-00:00' )
		end


		it "matches wrapped day number range values as two ranges covering the upper and lower parts" do
			schedule = described_class.parse( "md {28-2}" )

			expect( schedule ).to_not include( '2015-12-27T23:59:59-00:00' )
			expect( schedule ).to include( '2015-12-28T00:00:00-00:00' )
			expect( schedule ).to include( '2015-12-30T00:00:00-00:00' )
			expect( schedule ).to include( '2015-12-31T00:00:00-00:00' )
			expect( schedule ).to include( '2016-01-01T00:00:00-00:00' )
			expect( schedule ).to include( '2016-01-02T23:59:59-00:00' )
			expect( schedule ).to include( '2016-02-29T00:00:00-00:00' )
			expect( schedule ).to_not include( '2016-01-03T00:00:00-00:00' )
		end


		it "matches single week number values against the counted week of the month" do
			schedule = described_class.parse( "wk {2}" )

			expect( schedule ).to_not include( '2016-04-01T00:00:00-00:00' )
			expect( schedule ).to_not include( '2016-04-02T00:00:00-00:00' )
			expect( schedule ).to_not include( '2016-04-02T23:59:59-00:00' )
			expect( schedule ).to_not include( '2016-04-03T00:00:00-00:00' )
			expect( schedule ).to_not include( '2016-04-04T03:00:00-00:00' )
			expect( schedule ).to_not include( '2016-04-05T06:00:00-00:00' )
			expect( schedule ).to_not include( '2016-04-06T09:00:00-00:00' )
			expect( schedule ).to_not include( '2016-04-07T23:59:59-00:00' )

			expect( schedule ).to include( '2016-04-08T15:00:00-00:00' )
			expect( schedule ).to include( '2016-04-09T19:00:00-00:00' )
			expect( schedule ).to include( '2016-04-10T00:00:00-00:00' )
			expect( schedule ).to include( '2016-04-11T00:00:00-00:00' )
			expect( schedule ).to include( '2016-04-12T00:00:00-00:00' )
			expect( schedule ).to include( '2016-04-13T00:00:00-00:00' )
			expect( schedule ).to include( '2016-04-14T23:59:59-00:00' )

			expect( schedule ).to_not include( '2016-04-15T00:00:00-00:00' )
			expect( schedule ).to_not include( '2016-04-28T00:00:00-00:00' )
		end


		it "matches week number range values as multi-day inclusive ranges" do
			schedule = described_class.parse( "wk {2-4}" )

			expect( schedule ).to_not include( '2016-04-01T00:00:00-00:00' )
			expect( schedule ).to_not include( '2016-04-02T00:00:00-00:00' )
			expect( schedule ).to_not include( '2016-04-07T23:59:59-00:00' )

			expect( schedule ).to include( '2016-04-08T00:00:00-00:00' )
			expect( schedule ).to include( '2016-04-10T00:00:00-00:00' )
			expect( schedule ).to include( '2016-04-17T00:00:00-00:00' )
			expect( schedule ).to include( '2016-04-28T23:59:59-00:00' )

			expect( schedule ).to_not include( '2016-04-29T00:00:00-00:00' )
			expect( schedule ).to_not include( '2016-04-30T00:00:00-00:00' )
		end


		it "matches wrapped week number range values as two ranges covering the upper and lower parts" do
			schedule = described_class.parse( "wk {4-1}" )

			expect( schedule ).to include( '2016-04-01T00:00:00-00:00' )
			expect( schedule ).to include( '2016-04-02T00:00:00-00:00' )
			expect( schedule ).to include( '2016-04-07T23:59:59-00:00' )

			expect( schedule ).to_not include( '2016-04-08T00:00:00-00:00' )
			expect( schedule ).to_not include( '2016-04-10T00:00:00-00:00' )
			expect( schedule ).to_not include( '2016-04-20T23:59:59-00:00' )

			expect( schedule ).to include( '2016-04-28T00:00:00-00:00' )
			expect( schedule ).to include( '2016-04-29T00:00:00-00:00' )
			expect( schedule ).to include( '2016-04-30T23:59:59-00:00' )
		end


		it "matches single day of week values as a 86400-second exclusive range" do
			schedule = described_class.parse( "wd {Wed}" )

			expect( schedule ).to_not include( 'Tue, 01 Dec 2015 00:00:00 GMT' )
			expect( schedule ).to_not include( 'Tue, 01 Dec 2015 23:59:59 GMT' )
			expect( schedule ).to include( 'Wed, 02 Dec 2015 00:00:00 GMT' )
			expect( schedule ).to include( 'Wed, 02 Dec 2015 12:00:00 GMT' )
			expect( schedule ).to include( 'Wed, 02 Dec 2015 23:59:59 GMT' )
			expect( schedule ).to_not include( 'Thu, 03 Dec 2015 00:00:00 GMT' )
		end


		it "matches single numeric day of week value as a 86400-second exclusive range" do
			schedule = described_class.parse( "wd {6}" )

			expect( schedule ).to_not include( 'Fri, 01 Jan 2016 00:00:00 GMT' )
			expect( schedule ).to_not include( 'Fri, 01 Jan 2016 23:59:59 GMT' )
			expect( schedule ).to include( 'Sat, 02 Jan 2016 00:00:00 GMT' )
			expect( schedule ).to include( 'Sat, 02 Jan 2016 12:00:00 GMT' )
			expect( schedule ).to include( 'Sat, 02 Jan 2016 23:59:59 GMT' )
			expect( schedule ).to_not include( 'Sun, 03 Jan 2016 00:00:00 GMT' )
		end


		it "matches day of week name ranges as an inclusive range" do
			schedule = described_class.parse( "wd {Mon-Fri}" )

			expect( schedule ).to_not include( 'Sun, 03 Jan 2016 23:59:59 GMT' )
			expect( schedule ).to include( 'Mon, 04 Jan 2016 00:00:00 GMT' )
			expect( schedule ).to include( 'Wed, 06 Jan 2016 00:00:00 GMT' )
			expect( schedule ).to include( 'Fri, 08 Jan 2016 23:59:59 GMT' )
			expect( schedule ).to_not include( 'Sat, 09 Jan 2016 00:00:00 GMT' )
			expect( schedule ).to_not include( 'Sat, 09 Jan 2016 23:59:59 GMT' )
		end


		it "matches day of week wrapped name ranges as a set of two ranges of the included days" do
			schedule = described_class.parse( "wd {Fri-Sun}" )

			expect( schedule ).to_not include( 'Mon, 04 Jan 2016 00:00:00 GMT' )
			expect( schedule ).to_not include( 'Thu, 07 Jan 2016 23:59:59 GMT' )
			expect( schedule ).to include( 'Fri, 08 Jan 2016 00:00:00 GMT' )
			expect( schedule ).to include( 'Sat, 09 Jan 2016 12:00:00 GMT' )
			expect( schedule ).to include( 'Sun, 10 Jan 2016 23:59:59 GMT' )
			expect( schedule ).to_not include( 'Mon, 11 Jan 2016 00:00:00 GMT' )
			expect( schedule ).to_not include( 'Mon, 11 Jan 2016 23:59:59 GMT' )
		end


		it "matches single month name values as a single-month exclusive range" do
			schedule = described_class.parse( "mo {Dec}" )

			expect( schedule ).to_not include( 'Mon, 30 Nov 2015 23:59:59 GMT' )
			expect( schedule ).to include( 'Tue, 01 Dec 2015 00:00:00 GMT' )
			expect( schedule ).to include( 'Tue, 15 Dec 2015 00:00:00 GMT' )
			expect( schedule ).to include( 'Thu, 31 Dec 2015 23:59:59 GMT' )
			expect( schedule ).to_not include( 'Fri, 01 Jan 2016 00:00:00 GMT' )
		end


		it "matches single month number values as a single-month exclusive range" do
			schedule = described_class.parse( "mo {7}" )

			expect( schedule ).to_not include( '2015-06-30T23:59:59-00:00' )
			expect( schedule ).to include( '2015-07-01T00:00:00-00:00' )
			expect( schedule ).to include( '2015-07-15T23:59:59-00:00' )
			expect( schedule ).to include( '2015-07-31T23:59:59-00:00' )
			expect( schedule ).to_not include( '2015-08-01T00:00:00-00:00' )
		end


		it "matches a range of month name values as a inclusive range" do
			schedule = described_class.parse( "mo {Aug-Nov}" )

			expect( schedule ).to_not include( 'Fri, 31 Jul 2015 23:59:59 GMT' )
			expect( schedule ).to include( 'Sat, 01 Aug 2015 00:00:00 GMT' )
			expect( schedule ).to include( 'Thu, 15 Oct 2015 00:00:00 GMT' )
			expect( schedule ).to include( 'Mon, 30 Nov 2015 23:59:59 GMT' )
			expect( schedule ).to_not include( 'Tue, 01 Dec 2015 00:00:00 GMT' )
		end


		it "matches every month other than those in a negated range of month names" do
			schedule = described_class.parse( "not mo {Aug-Nov}" )

			expect( schedule ).to include( 'Fri, 31 Jul 2015 23:59:59 GMT' )
			expect( schedule ).to_not include( 'Sat, 01 Aug 2015 00:00:00 GMT' )
			expect( schedule ).to_not include( 'Thu, 15 Oct 2015 00:00:00 GMT' )
			expect( schedule ).to_not include( 'Mon, 30 Nov 2015 23:59:59 GMT' )
			expect( schedule ).to include( 'Tue, 01 Dec 2015 00:00:00 GMT' )
		end


		it "matches a wrapped range of month name values as two inclusive ranges" do
			schedule = described_class.parse( "mo {Sep-Mar}" )

			expect( schedule ).to_not include( 'Mon, 31 Aug 2015 23:59:59 GMT' )
			expect( schedule ).to include( 'Tue, 01 Sep 2015 00:00:00 GMT' )
			expect( schedule ).to include( 'Thu, 15 Oct 2015 00:00:00 GMT' )
			expect( schedule ).to include( 'Mon, 30 Nov 2015 23:59:59 GMT' )
			expect( schedule ).to include( 'Thu, 31 Dec 2015 23:59:59 GMT' )
			expect( schedule ).to include( 'Fri, 01 Jan 2016 00:00:00 GMT' )
			expect( schedule ).to include( 'Thu, 31 Mar 2016 23:59:59 GMT' )
			expect( schedule ).to_not include( 'Fri, 01 Apr 2016 00:00:00 GMT' )
		end


		it "matches single day-of-year values as a single 24-hour period" do
			schedule = described_class.parse( "yd {362}" )

			expect( schedule ).to_not include( '2015-12-27T23:59:59-00:00' )
			expect( schedule ).to include( '2015-12-28T00:00:00-00:00' )
			expect( schedule ).to include( '2015-12-28T12:00:00-00:00' )
			expect( schedule ).to include( '2015-12-28T23:59:59-00:00' )
			expect( schedule ).to_not include( '2015-12-29T00:00:00-00:00' )
		end


		it "matches a range of day-of-year values as an inclusive range" do
			schedule = described_class.parse( "yd {362-365}" )

			expect( schedule ).to_not include( '2015-12-27T23:59:59-00:00' )
			expect( schedule ).to include( '2015-12-28T00:00:00-00:00' )
			expect( schedule ).to include( '2015-12-29T12:00:00-00:00' )
			expect( schedule ).to include( '2015-12-30T18:00:00-00:00' )
			expect( schedule ).to include( '2015-12-31T23:59:59-00:00' )
			expect( schedule ).to_not include( '2016-01-01T00:00:00-00:00' )
		end


		it "matches a wrapped range of day-of-year values as two inclusive ranges" do
			schedule = described_class.parse( "yd {362-15}" )

			expect( schedule ).to_not include( '2015-12-27T23:59:59-00:00' )
			expect( schedule ).to include( '2015-12-28T00:00:00-00:00' )
			expect( schedule ).to include( '2015-12-29T12:00:00-00:00' )
			expect( schedule ).to include( '2015-12-30T18:00:00-00:00' )
			expect( schedule ).to include( '2015-12-31T23:59:59-00:00' )
			expect( schedule ).to include( '2016-01-01T00:00:00-00:00' )
			expect( schedule ).to include( '2016-01-11T00:00:00-00:00' )
			expect( schedule ).to include( '2016-01-15T23:59:59-00:00' )
			expect( schedule ).to_not include( '2016-01-16T00:00:00-00:00' )
		end


		it "handles day-of-year values during a leap-year correctly" do
			schedule = described_class.parse( "yd {366}" )

			expect( schedule ).to_not include( '2016-12-30T23:59:59-00:00' )
			expect( schedule ).to include( '2016-12-31T00:00:00-00:00' )
			expect( schedule ).to include( '2016-12-31T23:59:59-00:00' )
			expect( schedule ).to_not include( '2017-01-01T00:00:00-00:00' )
		end


		it "matches single year values as a single-year exclusive range" do
			schedule = described_class.parse( "yr {2019}" )

			expect( schedule ).to_not include( '2018-12-31T23:59:59-00:00' )
			expect( schedule ).to include( '2019-01-01T00:00:00-00:00' )
			expect( schedule ).to include( '2019-06-15T00:00:00-00:00' )
			expect( schedule ).to include( '2019-12-31T23:59:59-00:00' )
			expect( schedule ).to_not include( '2020-01-01T00:00:00-00:00' )
		end


		it "matches year range values as multi-year inclusive ranges" do
			schedule = described_class.parse( "yr {2009-2015}" )

			expect( schedule ).to_not include( '2008-12-31T23:59:59-00:00' )
			expect( schedule ).to include( '2009-01-01T00:00:00-00:00' )
			expect( schedule ).to include( '2011-06-15T00:00:00-00:00' )
			expect( schedule ).to include( '2015-12-31T23:59:59-00:00' )
			expect( schedule ).to_not include( '2016-01-01T00:00:00-00:00' )
		end


		it "matches negative year range values as multi-year inclusive ranges" do
			schedule = described_class.parse( "! yr {2009-2015}" )

			expect( schedule ).to include( '2008-12-31T23:59:59-00:00' )
			expect( schedule ).to_not include( '2009-01-01T00:00:00-00:00' )
			expect( schedule ).to_not include( '2011-06-15T00:00:00-00:00' )
			expect( schedule ).to_not include( '2015-12-31T23:59:59-00:00' )
			expect( schedule ).to include( '2016-01-01T00:00:00-00:00' )
		end


		it "raises an error for wrapped year ranges" do
			expect {
				described_class.parse( "yr {2015-2013}" )
			}.to raise_error( Schedulability::ParseError, /wrapped year range/i )
		end


		it "raises an error for invalid years" do
			expect {
				described_class.parse( "yr {76}" )
			}.to raise_error( Schedulability::ParseError, /invalid year value: 76/i )
		end


		it "raises a parse error for invalid scales" do
			expect {
				described_class.parse( 'mil {2}' )
			}.to raise_error( Schedulability::ParseError, /malformed schedule/i )
		end


		it "raises a parse error for invalid hour periods" do
			expect {
				described_class.parse( 'hr {2yt}' )
			}.to raise_error( Schedulability::ParseError, /invalid hour range: "2yt"/i )
			expect {
				described_class.parse( 'hr {14pm}' )
			}.to raise_error( Schedulability::ParseError, /invalid hour value: "14pm"/i )
			expect {
				described_class.parse( 'hr {14am}' )
			}.to raise_error( Schedulability::ParseError, /invalid hour value: "14am"/i )
			expect {
				described_class.parse( 'hr {28}' )
			}.to raise_error( Schedulability::ParseError, /invalid hour value: "28"/i )
		end


		it "raises a parse error for day of month values greater than 31" do
			expect {
				described_class.parse( 'md {11 21 88}' )
			}.to raise_error( Schedulability::ParseError, /invalid mday value: 88/i )
		end


		it "raises a parse error for day of month ranges greater than 31" do
			expect {
				described_class.parse( 'md {28-35}' )
			}.to raise_error( Schedulability::ParseError, /invalid mday value: 35/i )
		end


		it "raises a parse error for day of week numbers greater than 6" do
			expect {
				described_class.parse( 'wd {2 5 7}' )
			}.to raise_error( Schedulability::ParseError, /invalid wday value: 7/i )
		end


		it "raises a parse error for day of week ranges which include a value greater than 6" do
			expect {
				described_class.parse( 'wd {8-2}' )
			}.to raise_error( Schedulability::ParseError, /invalid wday value: 8/i )
		end


		it "raises a parse error for non-existant month names" do
			expect {
				described_class.parse( 'mo {Fit}' )
			}.to raise_error( Schedulability::ParseError, /invalid month value: "Fit"/i )
		end


		it "raises a parse error for second values greater than 59" do
			expect {
				described_class.parse( 'sec {74 18}' )
			}.to raise_error( Schedulability::ParseError, /invalid second value: 74/i )
			expect {
				described_class.parse( 'sec {60}' )
			}.to raise_error( Schedulability::ParseError, /invalid second value: 60/i )
		end


		it "raises a parse error for second ranges with invalid values" do
			expect {
				described_class.parse( 'sec {55-60}' )
			}.to raise_error( Schedulability::ParseError, /invalid second value: 60/i )
		end


		it "doesn't raise a parse error for second values equal to 59" do
			expect {
				described_class.parse( 'sec {1 5 10 59}' )
			}.not_to raise_error
			expect {
				described_class.parse( 'sec {59}' )
			}.not_to raise_error
			expect {
				described_class.parse( 'sec {0-59}' )
			}.not_to raise_error
		end


		it "allows second values equal to 0" do
			expect {
				described_class.parse( 'sec {0 5 10 59}' )
			}.not_to raise_error
			expect {
				described_class.parse( 'sec {0}' )
			}.not_to raise_error
			expect {
				described_class.parse( 'sec {0-59}' )
			}.not_to raise_error
		end


		it "raises a parse error for minute values greater than 59" do
			expect {
				described_class.parse( 'min {09 28 68}' )
			}.to raise_error( Schedulability::ParseError, /invalid minute value: 68/i )
			expect {
				described_class.parse( 'min {60}' )
			}.to raise_error( Schedulability::ParseError, /invalid minute value: 60/i )
		end


		it "doesn't raise a parse error for minute values equal to 59" do
			expect {
				described_class.parse( 'min {1 5 10 59}' )
			}.not_to raise_error
			expect {
				described_class.parse( 'min {59}' )
			}.not_to raise_error
			expect {
				described_class.parse( 'min {0-59}' )
			}.not_to raise_error
		end


		it "allows minute values equal to 0" do
			expect {
				described_class.parse( 'min {0 5 10 59}' )
			}.not_to raise_error
			expect {
				described_class.parse( 'min {0}' )
			}.not_to raise_error
			expect {
				described_class.parse( 'min {0-59}' )
			}.not_to raise_error
		end


		it "raises a parse error for minute ranges with invalid values" do
			expect {
				described_class.parse( 'min {120-15}' )
			}.to raise_error( Schedulability::ParseError, /invalid minute value: 120/i )
		end


		it "raises a parse error for week values greater than 5" do
			expect {
				described_class.parse( 'wk {7}' )
			}.to raise_error( Schedulability::ParseError, /invalid week value: 7/i )
		end


		it "raises a parse error for week ranges that have a value greater than 5" do
			expect {
				described_class.parse( 'wk {2-11}' )
			}.to raise_error( Schedulability::ParseError, /invalid week value: 11/i )
		end


		it "supports pluralization syntactic sugar" do
			expect(
				described_class.parse("years {2001 2011 2021} months {Jul Sep}")
			).to be_a( described_class )
		end

		it "ignores whitespace in range values" do
			schedule = described_class.parse( "sec { 18 - 55   }" )
			expect( schedule ).to be_a( described_class )
		end

	end


	describe "mutators" do


		it "can calculate the union of two schedules" do
			schedule1 = described_class.parse( 'md {1-15}' )
			schedule2 = described_class.parse( 'month {Feb-Jul}' )
			schedule3 = schedule1 | schedule2

			expect( schedule3 ).to be == described_class.parse( 'md {1-15}, month {Feb-Jul}' )
		end


		it "can calculate the intersection of two schedules" do
			schedule1 = described_class.parse( 'md {1-15} month {Mar-Jun}' )
			schedule2 = described_class.parse( 'md {10-20} month {Feb-Jul}' )
			schedule3 = schedule1 & schedule2

			expect( schedule3 ).to be == described_class.parse( 'md {10-15} month {Mar-Jun}' )
		end


		it "returns an empty schedule as the intersection of two non-overlapping schedules" do
			schedule1 = described_class.parse( 'hr {6am-8am} wday {Mon Wed Fri}' )
			schedule2 = described_class.parse( 'wday {Thu Sat}' )
			schedule3 = schedule1 & schedule2

			expect( schedule3 ).to be_empty
		end


		it "treats scales present in one schedule as infinite in the other when intersecting" do
			schedule1 = described_class.parse( 'hr {6am-8am}' )
			schedule2 = described_class.parse( 'wday {Thu Sat}' )
			schedule3 = schedule1 & schedule2

			expect( schedule3 ).to be == described_class.parse( 'hr {6am-8am} wday {Thu Sat}' )
		end


		it "can calculate unions of schedules with negated periods" do
			schedule1 = described_class.parse( '! wday { Mon-Fri }' )
			schedule2 = described_class.parse( '! wday { Thu }' )
			schedule3 = schedule1 | schedule2

			expect( schedule3 ).to be == schedule2
		end


		it "can calculate unions of schedules with negated periods that don't overlap" do
			schedule1 = described_class.parse( '! wday { Wed }' )
			schedule2 = described_class.parse( '! wday { Thu }' )
			schedule3 = schedule1 | schedule2

			expect( schedule3 ).to be_empty
		end


		it "can calculate intersections of schedules with negated periods" do
			schedule1 = described_class.parse( '! wday { Wed }' )
			schedule2 = described_class.parse( '! wday { Thu }' )
			schedule3 = schedule1 & schedule2

			expect( schedule3 ).to be == described_class.parse( '! wday {Wed}, ! wday {Thu}' )
		end


		it "can calculate the inverse of a schedule" do
			schedule1 = described_class.parse( 'hr {8am-4pm} md {10-15}' )
			schedule2 = ~schedule1

			expect( schedule2 ).to include( '2015-01-09T08:00:00-00:00' )
			expect( schedule2 ).to include( '2015-01-10T07:59:59-00:00' )
			expect( schedule2 ).to_not include( '2015-01-10T08:00:00-00:00' )
			expect( schedule2 ).to_not include( '2015-01-15T15:59:59-00:00' )
			expect( schedule2 ).to include( '2015-01-15T16:00:00-00:00' )
		end

	end


	describe "predicates" do

		it "can test if one schedule overlaps another" do
			schedule1 = described_class.parse( "hr {8am - 5pm}" )
			schedule2 = described_class.parse( "hr {5pm - 8am}" )
			schedule3 = described_class.parse( "wd {Mon - Fri}" )

			expect( schedule1 ).to_not overlap( schedule2 )
			expect( schedule1 ).to overlap( schedule3 )
			expect( schedule2 ).to overlap( schedule3 )
		end


		it "can test if one schedule is exclusive of another" do
			schedule1 = described_class.parse( "hr {8am - 5pm}" )
			schedule2 = described_class.parse( "hr {5pm - 8am}" )
			schedule3 = described_class.parse( "wd {Mon - Fri}" )

			expect( schedule1 ).to be_exclusive_of( schedule2 )
			expect( schedule1 ).to_not be_exclusive_of( schedule3 )
			expect( schedule2 ).to_not be_exclusive_of( schedule3 )
		end

	end

end

