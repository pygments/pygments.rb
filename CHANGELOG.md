CHANGELOG
===========

Version 1.2.1 (2017/12/07)
-----------------------------

* Automatically update `lexers` cache on build [186](https://github.com/tmm1/pygments.rb/pull/186)
  * See [#185](https://github.com/tmm1/pygments.rb/pull/185) for the reason

Version 1.2.0 (2017/09/13)
-----------------------------

* Exclude symlinks from the gem package to solve Windows issues [#181](https://github.com/tmm1/pygments.rb/pull/181)
* Upgrade pygments to 2.0.0 [#180](https://github.com/tmm1/pygments.rb/pull/180)

Version 1.1.2 (2017/04/03)
-----------------------------

* Resolves #176 exclude find_error.py symlink from gem [#177](https://github.com/tmm1/pygments.rb/pull/177)

Version 1.1.1 (2016/12/28)
-----------------------------

* Suppress Ruby 2.4.0's warnings [#172](https://github.com/tmm1/pygments.rb/pull/172)
* Enable `frozen_string_literal` [#173](https://github.com/tmm1/pygments.rb/pull/173)

Version 1.1.0 (2016/12/24)
-----------------------------

* Support JRuby [#170](https://github.com/tmm1/pygments.rb/pull/170)
* Make pygments.rb thread safe [#171](https://github.com/tmm1/pygments.rb/pull/171)

Version 1.0.0 (2016/12/11)
-----------------------------

* Upgrade bundled pygments to 2.2.0-HEAD [#167](https://github.com/tmm1/pygments.rb/pull/167)
  * This includes **incompatible changes* because of upgrade of pygments.
    See http://pygments.org/ for details.
* Relax yajl-ruby dependency to "~> 1.2" [#164](https://github.com/tmm1/pygments.rb/pull/164)
* Python binary can be configured by `PYTMENTS_RB_PYTHON` env [#168](https://github.com/tmm1/pygments.rb/pull/168)
* Improved error messages when python binary is missing [#158](https://github.com/tmm1/pygments.rb/pull/158)


Version 0.5.4 (Nov 3, 2013)
-----------------------------

* Update lexers file

Version 0.5.3 (Sep 17, 2013)
-----------------------------

* Fixes for Slash lexer
* Improve highlighting for Slash lexer
* Upgrade to latest pygments (1.7, changes summary follows.  See pygments changelog for details)
  * Add Clay lexer
  * Add Perl 6 lexer
  * Add Swig lexer
  * Add nesC lexer
  * Add BlitzBasic lexer
  * Add EBNF lexer
  * Add Igor Pro lexer
  * Add Rexx lexer
  * Add Agda lexer
  * Recognize vim modelines
  * Improve Python 3 lexer
  * Improve Opa lexer
  * Improve Julia lexer
  * Improve Lasso lexer
  * Improve Objective C/C++ lexer
  * Improve Ruby lexer
  * Improve Stan lexer
  * Improve JavaScript lexer
  * Improve HTTP lexer
  * Improve Koka lexer
  * Improve Haxe lexer
  * Improve Prolog lexer
  * Improve F# lexer

Version 0.5.2 (July 17, 2013)
-----------------------------

* Add Slash lexer

Version 0.5.1 (June 25, 2013)
-----------------------------

* Ensure compatability across distros by detecting if `python2` is available

Version 0.5.0 (Apr 13, 2013)
-----------------------------

* Use #rstrip to fix table mode bug

Version 0.4.2 (Feb 25, 2013)
-----------------------------

* Add new lexers, including custom lexers

Version 0.3.7 (Jan 2, 2013)
-----------------------------

* Fixed missing custom lexers
* Added syntax highlighting for Hxml

Version 0.3.4 (Dec 28, 2012)
-----------------------------

* Add support for Windows
* Add MIT license


