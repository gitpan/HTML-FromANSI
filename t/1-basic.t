#!/usr/bin/perl -w
# $File: //member/autrijus/HTML-FromANSI/t/1-basic.t $ $Author: autrijus $
# $Revision: #4 $ $Change: 2623 $ $DateTime: 2001/12/16 00:05:58 $

use strict;
use subs 'fork';
use Term::ANSIColor;
use Test::More tests => 2;

use_ok('HTML::FromANSI');

my $text = ansi2html(color('bold blue'), "This text is bold blue.");

is($text, join('', split("\n", << '.')), 'basic encoding');
<pre><font face="fixedsys, lucida console, terminal, vga, monospace">
<font color="#aaaaaa"><span style="{letter-spacing: 0; font-size: 12pt;}">
</font><FONT color="#4444ff"></SPAN><SPAN style="{ background-color: #000000;}">
This&nbsp;text&nbsp;is&nbsp;bold&nbsp;blue.
</span></font>
</pre>
.
