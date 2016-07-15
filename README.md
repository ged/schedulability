# schedulability

home
: http://deveiate.org/projects/schedulability

code
: http://bitbucket.org/ged/schedulability

docs
: http://deveiate.org/code/schedulability

github
: http://github.com/ged/schedulability


## Description

Schedulability is a library for describing scheduled time. You can specify one
or more periods of time using a simple syntax, then combine them to describe
more-complex schedules.


## Usage

Schedules are represented with Schedulability::Schedule objects, which are
empty by default:

    schedule = Schedulability::Schedule.new
    # => #<Schedulability::Schedule:0x007ffcf2b982b8 (empty)>

An empty Schedule has no time restrictions, and will match any time.

To specify matching times, you'll need to construct a Schedule with one or more
periods.


### Periods

A schedule is made up of zero or more positive periods, and zero or more
negative periods. A time is within the schedule if at least one positive period
and no negative periods match it.

Periods are specified as a String that contains a comma-separated list of
period descriptions. The string `"never"` can be specified to explicitly create
a schedule which will not match any time.

A period description is of the form

    [!] scale {range [range ...]} [scale {range [range ...]}]

Negative periods begin with a `!`; you may also use `not` or `except` for
readability.

Scale must be one of nine different scales (or their equivalent codes):

    Scale  | Scale | Valid Range Values
           | Code  |
    -------+-------+------------------------------------------------------
    year   |  yr   | n     where n is a 4-digit integer
    month  |  mo   | 1-12  or  jan, feb, mar, apr, may, jun, jul,
           |       |           aug, sep, oct, nov, dec
    week   |  wk   | 1-6
    yday   |  yd   | 1-366
    mday   |  md   | 1-31
    wday   |  wd   | 1-7   or  sun, mon, tue, wed, thu, fri, sat
    hour   |  hr   | 0-23  or  12am 1am-11am 12noon 12pm 1pm-11pm
    minute |  min  | 0-59
    second |  sec  | 0-59

The same scale type may be specified multiple times. Additional scales are
unioned with the ranges defined by previous scales of the same type in the same
sub-period.

A `range` is specified in the form:

    <range value>
or

    <range value>-<range value>

For two-value ranges, the range is defined as the period between the first and
second `range value`s. Scales which are in seconds granularity are exclusive of
their end value, but the rest are inclusive. For example, `hr {9am-5pm}` means
9:00:00 AM until 4:59:59 PM, but `wd {Wed-Sat}` runs until one second before
midnight on Saturday.

If the first value is larger than the second value (e.g. `min {20-10}`), the
range wraps (except when the scale specification is `year`). For example,
`month {9-2}` is the same as specifying `month {1-2 9-12}` or `month {1-2}
month {9-12}` or even `month {Jan-Feb Sep-Dec}`.

The range specified by the single-value specification is implicitly between the
`range value` and its next sequential whole value. For example, `hr {9}` is the
same as specifying `hr {9-10}`, `mday {15}` is the same as `mday {15-16}`, etc.

Neither extra whitespace nor case are significant in a period description.
Scales must be specified either in long form (`year`, `month`, `week`, etc.) or
in code form (`yr`, `mo`, `wk`, etc.). Scale forms may be mixed in a period
statement.

Values for week days and months can be abbreviated to three characters
(`Wednesday` == `Wed`, `September` == `Sep`).


#### Period Examples

<dl>
<dt><code>wd {Mon-Fri} hr {9am-4pm}</code></dt>
<dd>Monday through Friday, 9am to 5pm</dd>

<dt><code>wd {Mon Wed Fri} hr {9am-4pm}, wd{Tue Thu} hr {9am-2pm}</code></dt>
<dd>Monday through Friday, 9:00:00am to 3:59:59pm on Monday, Wednesday, and 
	Friday, and 9:00:00am to 1:59:59pm on Tuesday and Thursday</dd>

<dt><code>wk {1 3 5} wd {Mon-Fri} hr {9am-5pm}</code></dt>
<dd>Mon-Fri 9:00:00am-4:59:59pm, on odd weeks in the month</dd>

<dt><code>month {Jan-Feb Nov-Dec}</code></dt>
<dd>During Winter in the northern hemisphere.</dd>

<dt><code>mo {Nov-Feb}</code></dt>
<dd>The same thing (Winter) as a wrapped range.</dd>

<dt><code>not mo {Mar-Oct}</code></dt>
<dd>The same thing (Winter) as a negative range.</dd>

<dt><code>mo {jan feb nov dec}</code></dt>
<dd>Northern Winter as single months</dd>

<dt><code>mo {Jan Feb}, mo {Nov Dec}</code></dt>
<dd>Also Northern Winter.</dd>

<dt><code>mo {Jan Feb} mo {Nov Dec}</code></dt>
<dd>Northern Winter.</dd>

<dt><code>minute { 0-29 }</code></dt>
<dd>The first half of every hour.</dd>

<dt><code>hour { 12am - 12pm }</code></dt>
<dd>During the morning.</dd>

<dt><code>sec {0-4 10-14 20-24 30-34 40-44 50-54}</code></dt>
<dd>Alternating 5-second periods every hour.</dd>

<dt><code>wd {mon wed fri} hr {8am - 5pm}, except day {1}</code></dt>
<dd>Every Monday, Wednesday, and Friday from 8am until 4:59:59 PM, except on 
	the first of the month.</dd>

<dt><code>wd {1 3 5 7} min {0-29}, wd {2 4 6} min {30-59}</code></dt>
<dd>Every first half-hour on alternating week days, and the second half-hour the
  rest of the week.</dd>
</dl>
        

### Schedule Objects

Schedules are immutable after they're created, but they have mutator methods to
allow you to compose the schedule you want by combining them, or by using
mutator methods that return a changed copy of the original:

    weekend = Schedulability::Schedule( "wd {Sat - Sun}" )
    weekdays = Schedulability::Schedule( "wd {Mon - Fri}" )
    work_hours = Schedulability::Schedule( "hour {9am - 5pm}" )
    off_hours = Schedulability::Schedule( "hour {5pm - 9am}" )

    ### Boolean operators
    on_duty = weekdays | work_hours
    off_duty = weekend + ( weekdays | off_hours )
    # -or-
    off_duty = ~on_duty

    ### Exclusivity predicates
    on_duty.overlaps?( off_duty )
    # => false
    on_duty.exclusive?( off_duty )
    # => true

    ### Time predicates
    Time.now
    # => 2015-12-22 12:05:44 -0800
    on_duty.include?( Time.now )
    # => true
    on_duty.now?
    # => true
    off_duty.now?
    # => false

    ### Case equality (=== operator)
    case Time.now
    when on_duty
        send_sms( "Stuff happened." )
    when off_duty
        send_email( "Stuff happened." )
    end


## Prerequisites

* Ruby 2.2.0 or better


## Installation

    $ gem install schedulability


## Contributing

You can check out the current development source with
[Mercurial](https://bitbucket.org/ged/schedulability), or if you prefer Git, via
[its Github mirror](https://github.com/ged/schedulability).

After checking out the source, run:

    $ rake newb

This task will install any missing dependencies, run the tests/specs,
and generate the API documentation.


## License

This library borrows much of its schedule description syntax and several
implementation strategies from the Time::Period Perl module by Patrick Ryan,
used under the terms of the Perl Artistic License.

> Patrick Ryan <perl@pryan.org> wrote it.
> Paul Boyd <pboyd@cpan.org> fixed a few bugs.
> 
> Copyright (c) 1997 Patrick Ryan. All rights reserved. This Perl 
> module uses the conditions given by Perl. This module may only
> be distributed and or modified under the conditions given by Perl.

The rest is:

Copyright (c) 2015, Michael Granger and Mahlon E. Smith
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the author/s, nor the names of the project's
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


