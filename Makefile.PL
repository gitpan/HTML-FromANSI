#!/usr/bin/perl
# $File: //member/autrijus/HTML-FromANSI/Makefile.PL $ $Author: autrijus $
# $Revision: #1 $ $Change: 2445 $ $DateTime: 2001/11/28 02:31:40 $

require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'Mark up ANSI sequences as HTML',
    NAME		=> 'HTML::FromANSI',
    VERSION_FROM	=> 'FromANSI.pm', 
    DISTNAME		=> 'HTML-FromANSI',
    BINARY_LOCATION	=> 'x86/HTML-FromANSI.tar.gz',

    PREREQ_PM		=> {
	'Test::More'	=> '0.11',
    },

    EXE_FILES		=> [ <bin/*> ],

    dist		=> {
        COMPRESS	=> 'gzip',
        SUFFIX		=> '.gz',
    },
);

