#!/usr/bin/perl
# $File: //member/autrijus/HTML-FromANSI/Makefile.PL $ $Author: autrijus $
# $Revision: #2 $ $Change: 3581 $ $DateTime: 2002/03/28 11:52:18 $

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
	'Term::VT102'	=> '0.01',
	'HTML::Entities'=> '0.01',
    },

    EXE_FILES		=> [ <bin/*> ],

    dist		=> {
        COMPRESS	=> 'gzip',
        SUFFIX		=> '.gz',
    },
);

