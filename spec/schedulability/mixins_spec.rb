#!/usr/bin/env rspec -cfd

require_relative '../helpers'

require 'schedulability/mixins'


describe Schedulability, 'mixins' do


	describe Schedulability::TimeRefinements do

		using( described_class )


		describe "used to extend Numeric objects" do

			SECONDS_IN_A_MINUTE    = 60
			SECONDS_IN_AN_HOUR     = SECONDS_IN_A_MINUTE * 60
			SECONDS_IN_A_DAY       = SECONDS_IN_AN_HOUR * 24
			SECONDS_IN_A_WEEK      = SECONDS_IN_A_DAY * 7
			SECONDS_IN_A_FORTNIGHT = SECONDS_IN_A_WEEK * 2
			SECONDS_IN_A_MONTH     = SECONDS_IN_A_DAY * 30
			SECONDS_IN_A_YEAR      = Integer( SECONDS_IN_A_DAY * 365.25 )


			it "can calculate the number of seconds for various units of time" do
				expect( 1.second ).to eq( 1 )
				expect( 14.seconds ).to eq( 14 )

				expect( 1.minute ).to eq( SECONDS_IN_A_MINUTE )
				expect( 18.minutes ).to eq( SECONDS_IN_A_MINUTE * 18 )

				expect( 1.hour ).to eq( SECONDS_IN_AN_HOUR )
				expect( 723.hours ).to eq( SECONDS_IN_AN_HOUR * 723 )

				expect( 1.day ).to eq( SECONDS_IN_A_DAY )
				expect( 3.days ).to eq( SECONDS_IN_A_DAY * 3 )

				expect( 1.week ).to eq( SECONDS_IN_A_WEEK )
				expect( 28.weeks ).to eq( SECONDS_IN_A_WEEK * 28 )

				expect( 1.fortnight ).to eq( SECONDS_IN_A_FORTNIGHT )
				expect( 31.fortnights ).to eq( SECONDS_IN_A_FORTNIGHT * 31 )

				expect( 1.month ).to eq( SECONDS_IN_A_MONTH )
				expect( 67.months ).to eq( SECONDS_IN_A_MONTH * 67 )

				expect( 1.year ).to eq( SECONDS_IN_A_YEAR )
				expect( 13.years ).to eq( SECONDS_IN_A_YEAR * 13 )
			end


			it "can calculate various time offsets" do
				starttime = Time.now

				expect( 1.second.after( starttime ) ).to eq( starttime + 1 )
				expect( 18.seconds.from_now ).to be_within( 10.seconds ).of( starttime + 18 )

				expect( 1.second.before( starttime ) ).to eq( starttime - 1 )
				expect( 3.hours.ago ).to be_within( 10.seconds ).of( starttime - 10800 )
			end

		end


		context "used to extend Time objects" do

			it "makes them aware of whether they're in the future or not" do
				Timecop.freeze do
					time = Time.now
					expect( time.future? ).to be_falsey

					future_time = time + 1
					expect( future_time.future? ).to be_truthy

					past_time = time - 1
					expect( past_time.future? ).to be_falsey
				end
			end


			it "makes them aware of whether they're in the past or not" do
				Timecop.freeze do
					time = Time.now
					expect( time.past? ).to be_falsey

					future_time = time + 1
					expect( future_time.past? ).to be_falsey

					past_time = time - 1
					expect( past_time.past? ).to be_truthy
				end
			end


			it "adds the ability to express themselves as an offset in English" do
				Timecop.freeze do
					expect( 1.second.ago.as_delta ).to eq( 'less than a minute ago' )
					expect( 1.second.from_now.as_delta ).to eq( 'less than a minute from now' )

					expect( 1.minute.ago.as_delta ).to eq( 'a minute ago' )
					expect( 1.minute.from_now.as_delta ).to eq( 'a minute from now' )
					expect( 68.seconds.ago.as_delta ).to eq( 'a minute ago' )
					expect( 68.seconds.from_now.as_delta ).to eq( 'a minute from now' )
					expect( 2.minutes.ago.as_delta ).to eq( '2 minutes ago' )
					expect( 2.minutes.from_now.as_delta ).to eq( '2 minutes from now' )
					expect( 38.minutes.ago.as_delta ).to eq( '38 minutes ago' )
					expect( 38.minutes.from_now.as_delta ).to eq( '38 minutes from now' )

					expect( 1.hour.ago.as_delta ).to eq( 'about an hour ago' )
					expect( 1.hour.from_now.as_delta ).to eq( 'about an hour from now' )
					expect( 75.minutes.ago.as_delta ).to eq( 'about an hour ago' )
					expect( 75.minutes.from_now.as_delta ).to eq( 'about an hour from now' )

					expect( 2.hours.ago.as_delta ).to eq( '2 hours ago' )
					expect( 2.hours.from_now.as_delta ).to eq( '2 hours from now' )
					expect( 14.hours.ago.as_delta ).to eq( '14 hours ago' )
					expect( 14.hours.from_now.as_delta ).to eq( '14 hours from now' )

					expect( 22.hours.ago.as_delta ).to eq( 'about a day ago' )
					expect( 22.hours.from_now.as_delta ).to eq( 'about a day from now' )
					expect( 28.hours.ago.as_delta ).to eq( 'about a day ago' )
					expect( 28.hours.from_now.as_delta ).to eq( 'about a day from now' )

					expect( 36.hours.ago.as_delta ).to eq( '2 days ago' )
					expect( 36.hours.from_now.as_delta ).to eq( '2 days from now' )
					expect( 4.days.ago.as_delta ).to eq( '4 days ago' )
					expect( 4.days.from_now.as_delta ).to eq( '4 days from now' )

					expect( 1.week.ago.as_delta ).to eq( 'about a week ago' )
					expect( 1.week.from_now.as_delta ).to eq( 'about a week from now' )
					expect( 8.days.ago.as_delta ).to eq( 'about a week ago' )
					expect( 8.days.from_now.as_delta ).to eq( 'about a week from now' )

					expect( 15.days.ago.as_delta ).to eq( '2 weeks ago' )
					expect( 15.days.from_now.as_delta ).to eq( '2 weeks from now' )
					expect( 3.weeks.ago.as_delta ).to eq( '3 weeks ago' )
					expect( 3.weeks.from_now.as_delta ).to eq( '3 weeks from now' )

					expect( 1.month.ago.as_delta ).to eq( '4 weeks ago' )
					expect( 1.month.from_now.as_delta ).to eq( '4 weeks from now' )
					expect( 36.days.ago.as_delta ).to eq( '5 weeks ago' )
					expect( 36.days.from_now.as_delta ).to eq( '5 weeks from now' )

					expect( 6.months.ago.as_delta ).to eq( '6 months ago' )
					expect( 6.months.from_now.as_delta ).to eq( '6 months from now' )
					expect( 14.months.ago.as_delta ).to eq( '14 months ago' )
					expect( 14.months.from_now.as_delta ).to eq( '14 months from now' )

					expect( 6.year.ago.as_delta ).to eq( '6 years ago' )
					expect( 6.year.from_now.as_delta ).to eq( '6 years from now' )
					expect( 14.years.ago.as_delta ).to eq( '14 years ago' )
					expect( 14.years.from_now.as_delta ).to eq( '14 years from now' )
				end
			end

		end

	end


end

