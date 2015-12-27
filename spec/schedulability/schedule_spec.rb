#!/usr/bin/env rspec -cfd

require_relative '../helpers'

require 'time'
require 'timecop'
require 'schedulability/schedule'


describe Schedulability::Schedule do

	let( :testing_time ) { Time.parse('Tue Dec 15 12:00:00 2015') }


	context "with no periods" do

		let( :schedule ) { described_class.new }


		it "is empty" do
			expect( schedule ).to be_empty
		end


		it "is never 'now'" do
			Timecop.freeze( testing_time ) do
				expect( schedule ).to_not be_now
			end
		end


		it "never includes a particular time" do
			expect( schedule ).to_not include( testing_time )
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

	end



	describe "period parsing" do


		xit "matches single second values only during that second of every minute" do
			schedule = described_class.parse( "sec {18}" )
			time = Time.parse( 'Tue Dec 15 12:00:18 2015' )

			expect( schedule ).to_not include( time - 2 )
			expect( schedule ).to_not include( time - 1 )
			expect( schedule ).to include( time )
			expect( schedule ).to_not include( time + 1 )
			expect( schedule ).to_not include( time + 2 )
		end


		xit "matches single minute values as a 60-second exclusive range" do
			schedule = described_class.parse( "min {28}" )
			time = Time.parse( 'Tue Dec 15 12:28:00 2015' )

			expect( schedule ).to_not include( time - 15 )
			expect( schedule ).to_not include( time - 1 )
			expect( schedule ).to include( time )
			expect( schedule ).to include( time + 38 )
			expect( schedule ).to include( time + 59 )
			expect( schedule ).to_not include( time + 60 )
			expect( schedule ).to_not include( time + 120 )
		end


		it "matches single hour values as a 3600-second exclusive range" do
			schedule = described_class.parse( "hr {8}" )
			time = Time.parse( 'Tue Dec 15  8:00:00 2015' )

			expect( schedule ).to_not include( time - 1 )
			expect( schedule ).to include( time )
			expect( schedule ).to include( time + 60 )
			expect( schedule ).to include( time + 1200 )
			expect( schedule ).to include( time + 3599 )
			expect( schedule ).to_not include( time + 3600 )
			expect( schedule ).to_not include( time + 5400 )
		end


		xit "matches single day number values as a 86400-second exclusive range" do
			schedule = described_class.parse( "md {11}" )
			time = Time.parse( 'Fri Dec 11  0:00:00 2015' )

			expect( schedule ).to_not include( time - 3600 )
			expect( schedule ).to_not include( time - 1 )
			expect( schedule ).to include( time )
			expect( schedule ).to include( time + 60 )
			expect( schedule ).to include( time + 1200 )
			expect( schedule ).to include( time + 3600 )
			expect( schedule ).to include( time + 40000 )
			expect( schedule ).to include( time + 86399 )
			expect( schedule ).to_not include( time + 86400 )
		end


		it "matches single day of week values as a 86400-second exclusive range" do
			schedule = described_class.parse( "wd {Wed}" )
			time = Time.parse( 'Wed Dec 2  0:00:00 2015' )

			expect( schedule ).to_not include( time - 3600 )
			expect( schedule ).to_not include( time - 1 )
			expect( schedule ).to include( time )
			expect( schedule ).to include( time + 60 )
			expect( schedule ).to include( time + 1200 )
			expect( schedule ).to include( time + 3600 )
			expect( schedule ).to include( time + 40000 )
			expect( schedule ).to include( time + 86399 )
			expect( schedule ).to_not include( time + 86400 )
		end


		xit "matches single month values as a single-month exclusive range" do
			schedule = described_class.parse( "mo {Dec}" )

			expect( schedule ).to_not include( '2015-11-30 11:59:59 PM UTC' )
			expect( schedule ).to include( '2015-12-01 12:00:00 AM UTC' )
			expect( schedule ).to include( '2015-12-15 11:59:59 PM UTC' )
			expect( schedule ).to include( '2015-12-31 11:59:59 PM UTC' )
			expect( schedule ).to_not include( '2016-01-01 12:00:00 AM UTC' )
		end


		it ""

	end

end

