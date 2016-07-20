## v0.2.0 [2016-07-20] Michael Granger <ged@FaerieMUD.org>

Bugfixes:
- fixes for the 0th second or minute, and the 59th second
  (thanks to Jason Rogers <jacaetevha@gmail.com> for the patch)
- Make Schedule#empty? take negative periods into account

Enhancements
- Add missing Schedule#overlaps? and #exclusive predicate methods.
- Add a Schedule#to_s that stringifies them back into schedule descriptions



## v0.1.0 [2015-12-30] Michael Granger <ged@FaerieMUD.org>

First release.  Happy New Year!

