#!/usr/bin/env rspec -cfd

require_relative '../helpers'

require 'schedulability/parser'


describe Schedulability::Parser do


	it "can parse a single time period structure from a string" do
		range, negative = described_class.extract_period( "min {25-35}" )

		expect( range ).to be_a( Hash )
		expect( range ).to include( min: [25...35] )
		expect( negative ).to be_falsey
	end


	it "parses single values as one-unit ranges" do
		range, _ = described_class.extract_period( "min {0 15 30 45}" )

		expect( range ).to be_a( Hash )
		expect( range ).to include( min: [0...1, 15...16, 30...31, 45...46] )
	end


	it "can parse a single negative time period structure from a string" do
		range, negative = described_class.extract_period( "except hr {6-8}" )

		expect( range ).to be_a( Hash )
		expect( range ).to include( hr: [6...8] )
		expect( negative ).to be_truthy
	end


	it "can parse multiple time period structures from string descriptions joined by commas" do
		positive, negative = described_class.extract_periods( "wd {Mon-Fri}, except hr {6am-8pm}" )
		expect( positive ).to eq( [{wd: [1..5]}] )
		expect( negative ).to eq( [{hr: [6...20]}] )
	end


	it "can stringify an array of parsed time period structures" do
		schedule_string = "wd { 1-5 }, hr { 6-19 }, min { 0 15 30 45 }"
		periods, _ = described_class.extract_periods( schedule_string )

		expect( described_class.stringify(periods) ).
			to eq( schedule_string )
	end


	describe "can extract Range objects from expressions" do

		describe "for years"
		describe "for months"
		describe "for weeks of the month"
		describe "for days of the year"
		describe "for days of the month"
		describe "for hours"
		describe "for minutes"
		describe "for seconds"

	end

end

