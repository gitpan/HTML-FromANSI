#!/usr/bin/perl -w
# $File: //member/autrijus/HTML-FromANSI/t/1-basic.t $ $Author: autrijus $
# $Revision: #6 $ $Change: 3623 $ $DateTime: 2002/04/01 19:57:32 $

use strict;
use Test::More tests => 2;

use_ok('HTML::FromANSI');

my $text = ansi2html("\x1b[1;34m", "This text is bold blue.");

is($text, join('', split("\n", << '.')), 'basic conversion');
<tt><font
 face='fixedsys, lucida console, terminal, vga, monospace'
 style='line-height: 1; letter-spacing: 0; font-size: 12pt'
><span style='color: blue; background: black; '>
This&nbsp;text&nbsp;is&nbsp;bold&nbsp;blue.
</span>
<span style='color: black; background: black; '><br></span>
</font></tt>
.
