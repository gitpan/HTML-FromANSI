# $File: //member/autrijus/HTML-FromANSI/FromANSI.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 2623 $ $DateTime: 2001/12/16 00:05:58 $

package HTML::FromANSI;
$HTML::FromANSI::VERSION = '0.02';

use strict;
use vars qw/@EXPORT/;
use base qw/Exporter/;

@EXPORT = '&ansi2html';

=head1 NAME

HTML::FromANSI - Mark up ANSI sequences as HTML

=head1 SYNOPSIS

    use HTML::FromANSI;
    use Term::ANSIColor;

    print ansi2html(color('bold blue'), "This text is bold blue.");

=head1 DESCRIPTION

This small module converts ANSI text sequences to corresponding HTML
codes, using stylesheets to control color and blinking properties.

It exports C<ansi2html> by default, which takes an array, joins it
it into a single scalar, and returns its HTML rendering.

=head1 CAVEATS

The implementation is exceptionally kludgey. I plan on fixing it in an
indeterminable future. It's nowhere need a top priority, though.

=cut

my (
    $text,      $strpos,     $new_text,   $line_pos,  $char,
    $ansi_code, $html_style, $html_color, $code_length,
);

my ($attribute, $attributes, @attributes, $this_line);

my (
    $attr,      $foreground,     $background, $blink,
    $old_style, $old_html_color, %ascii,
);

my ($spaces, $nbspaces, $backspaces, %styles, $STYLE);

sub init {
    return if $STYLE;
    local $/; $STYLE = <DATA>;

    $attr       = '0';
    $foreground = '37';
    $background = '40';
    $spaces     = ' ' x 92;
    $nbspaces   = $spaces . $spaces;
    $backspaces = "\x08" x 200;

    $blink = $old_style = $old_html_color = '';
    %ascii = map { $_ => chr($_) } ( 127 .. 255 );

    foreach ( split ( "\n", $STYLE ) ) {
        s/\x0a?\x0d/\n/g;
        /^([^\s]*)\s*(.*)$/;
        $styles{$1} = $2;
    }
}

sub ansi2html {
    init();

    return (
	'<pre><font face="fixedsys, lucida console, terminal, vga, monospace">'.
	'<font color="#aaaaaa"><span style="{letter-spacing: 0; font-size: 12pt;}">'.
	parseansi(join('', @_)).
	'</span></font>'.
	'</pre>' # The missing </font> supplied by parseansi
    );
}

sub parseansi {
    $text     = $_[0];
    $strpos   = 0;
    $new_text = '';

    $text =~ s/\x0d?\x0a/\x0d/g;
    $text =~ s/^.*\x1b\[1;1H//gs;
    $text =~ s/^.*\x1b\[2J//gs;
    $text =~ s/\x1b\[D/\x08/g;
    $text =~ s/\x1b\[([0-9]*)D/substr($backspaces, 0, $1)/ge;

    # Wrap text at 80 chars... there's gotta be an easier way of doing this

    $line_pos = 0;

    while ( $strpos < length($text) ) {
        $char = substr( $text, $strpos, 1 );

        if ( $char =~ /\x1b/ ) {
            $ansi_code = '';

            until ( $char =~ /[a-zA-Z]/ or $strpos > length($text) ) {
                $ansi_code .= $char;
                $strpos += 1;
                $char = substr( $text, $strpos, 1 );
            }

            $ansi_code .= $char;

            if ( $ansi_code =~ /\x1b\[([0-9]*)C/ ) {
                $line_pos += $1;
                $this_line .= substr( $nbspaces, 1, $1 );
                $new_text .= substr( $nbspaces,  1, $1 );
            }
            else {
                $new_text .= $ansi_code;
            }
        }
        elsif ( $char =~ /\x08/ ) {
            $line_pos -= 1;
            $new_text .= $char;
        }
        elsif ( $char =~ /\x0d/ ) {
            $strpos += 1;

            if ( $strpos < length($text) ) {
                $ansi_code = '';
                $char = substr( $text, $strpos, 1 );

                if ( $char =~ /\x1b/ ) {
                    until ( $char =~ /[a-zA-Z]/ or $strpos > length($text) ) {
                        $ansi_code .= $char;
                        $strpos += 1;
                        $char = substr( $text, $strpos, 1 );
                    }

                    $ansi_code .= $char;

                    if ( $ansi_code eq "\x1b[A" ) {
                        $ansi_code = '';
                        $strpos += 1;
                        $char = substr( $text, $strpos, 1 );

                        if ( $char eq "\x1b" ) {
                            until ( $char =~ /[a-zA-Z]/
                                or $strpos > length($text) )
                            {
                                $ansi_code .= $char;
                                $strpos += 1;
                                $char = substr( $text, $strpos, 1 );
                            }

                            $ansi_code .= $char;

                            if ( $ansi_code =~ /\x1b\[([0-9]+)C/ ) {
                                $new_text .=
                                  substr( $nbspaces, 0, $1 - $line_pos );
                                $line_pos = $1;
                            }
                            else {
                                $new_text .= $ansi_code;
                            }
                        }
                        else {
                            $this_line = $char;
                            $new_text .= "\x0d$char";
                            $line_pos = 1;
                        }
                    }
                    elsif ( $ansi_code =~ /\x1b\[([0-9]*)C/ ) {
                        $line_pos = $1;
                        $this_line = substr( $nbspaces, 1, $line_pos );
                        $new_text .= "\x0d$this_line";
                    }
                    else {
                        $new_text .= "\x0d$ansi_code";
                        $line_pos  = 0;
                        $this_line = '';
                    }
                }
                else {
                    $new_text .= "\x0d";
                    $line_pos  = 0;
                    $this_line = '';
                    $strpos -= 1;
                }
            }
            else {
                $new_text .= "\x0d";
                $line_pos  = 0;
                $this_line = '';
                $strpos -= 1;
            }
        }
        else {
            $this_line .= $char;
            $line_pos += 1;
            $new_text .= $char;
        }

        if ( $line_pos > 79 ) {
            $this_line = '';
            $line_pos  = 0;
            $new_text .= "\x0d";
            $strpos += 1;

            if ( $strpos < length($text) ) {
                $char = substr( $text, $strpos, 1 );
                if ( $char ne "\x0d" ) {
                    $strpos -= 1;
                }
            }
        }

        $strpos += 1;
    }

    $text     = $new_text;
    $new_text = '';

    $text =~ s/\x1b\[C/ /g;
    $text =~ s/\x1b\[([0-9]*)C/substr($nbspaces,0,$1)/ge;

    while ( $text =~ s/[^\x0d\x08]\x08//g ) { }

    $text =~ s/\x08//g;
    $text =~ s/\x0d/\n/g;
    $text =~ s/\</&lt;/g;
    $text =~ s/\>/&gt;/g;

    $text =~ s/ /&nbsp;/g;
    $text =~ s/\x1b\[K//g;
    $text =~ s/\x1b\[A//g;
    $text =~ s/([\x7f-\xff])/$ascii{ord($1)}/ge;
    $text =~ s/\x1b\[[^a-zA-Z]*[a-ln-zA-Z]//g;
    $strpos = 0;

    while ( $strpos < length($text) ) {
        $char = substr( $text, $strpos, 1 );

        if ( $char ne "\x1b" ) {
            if ( $char eq '('
                && substr( $text, $strpos + 1, 1 ) ne "'"
                && substr( $text, $strpos + 1, 1 ) ne '1' )
            {
                $styles{".a$blink-$attr-$foreground-$background"} =~
                  /(?<=[\s{])color: ([^;]*); /;
                $html_color = $1;
                $html_style = $styles{".a$blink-$attr-$foreground-$background"};
                $html_style =~ s/(?<=[\s{])color: ([^;]*);//g;

                $new_text .= "</font><FONT color=\"$html_color\">"
                  if ( $old_html_color ne $html_color );
                $new_text .= "</SPAN><SPAN style=\"$html_style\">"
                  if ( $html_style ne $old_style );

                $old_style      = $html_style;
                $old_html_color = $html_color;
            }

            $new_text .= $char;
            $strpos += 1;
        }
        else {
            $code_length = 1;
            while ( substr( $text, $strpos + $code_length, 1 ) ne 'm'
                && $strpos + $code_length - 2 < length($text) )
            {
                $code_length += 1;
            }

            $ansi_code  = substr( $text, $strpos, $code_length + 1 );
            $attributes = $ansi_code;
            $attributes =~ s/[^0-9;]//g;
            @attributes = split ( /;/, $attributes );

            foreach $attribute (@attributes) {
                if ( $attribute eq '0' ) {
                    $attr       = '0';
                    $foreground = '37';
                    $background = '40';
                    $blink      = '';
                }
                elsif ( $attribute eq '1' ) {
                    $attr = '1';
                }
                elsif ( $attribute eq '5' ) {
                    $blink = '5';
                }
                elsif ( $attribute =~ m/^3[0-7]$/ ) {
                    $foreground = $attribute;
                }
                elsif ( $attribute =~ m/^4[0-7]$/ ) {
                    $background = $attribute;
                }
            }

            $styles{".a$blink-$attr-$foreground-$background"} =~
		/(?<=[\s{])color: ([^;]*);/;

            $html_color = $1;
            $html_style = $styles{".a$blink-$attr-$foreground-$background"};
            $html_style =~ s/(?<=[\s{])color: ([^;]*);//g;

            $new_text .= "</font><FONT color=\"$html_color\">"
              if ( defined $html_color && $old_html_color ne $html_color );
            $new_text .= "</SPAN><SPAN style=\"$html_style\">"
              if ( defined $html_style && $html_style ne $old_style );

            $old_style      = $html_style if defined $html_style;
            $old_html_color = $html_color if defined $html_color;
            $strpos += length($ansi_code);
        }
    }

    $new_text;
}

1;

=head1 SEE ALSO

L<ansi2html>, L<Term::ANSIColor>, L<Term::ANSIScreen>.

=head1 AUTHORS

Stephen Hurd E<lt>shurd@sk.sympatico.caE<gt>,
Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

=head1 COPYRIGHT

Copyright 2001 by Stephen Hurd E<lt>shurd@sk.sympatico.caE<gt>.

Picked up, cleaned up various bits, fixed bugs and turned into a
CPAN module by Autrijus Tang.

Copyright 2001 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

__DATA__
a              {text-decoration: none;}
a:hover        {text-decoration: underline;}
a:visited      {text-decoration: none;}
a:link         {text-decoration: none;}
.a-0-30-40     {color: #000000; background-color: #000000;}
.a-0-31-40     {color: #aa0000; background-color: #000000;}
.a-0-32-40     {color: #00aa00; background-color: #000000;}
.a-0-33-40     {color: #aaaa00; background-color: #000000;}
.a-0-34-40     {color: #0000aa; background-color: #000000;}
.a-0-35-40     {color: #aa00aa; background-color: #000000;}
.a-0-36-40     {color: #00aaaa; background-color: #000000;}
.a-0-37-40     {color: #aaaaaa; background-color: #000000;}
.a-1-30-40     {color: #444444; background-color: #000000;}
.a-1-31-40     {color: #ff4444; background-color: #000000;}
.a-1-32-40     {color: #44ff44; background-color: #000000;}
.a-1-33-40     {color: #ffff44; background-color: #000000;}
.a-1-34-40     {color: #4444ff; background-color: #000000;}
.a-1-35-40     {color: #ff44ff; background-color: #000000;}
.a-1-36-40     {color: #44ffff; background-color: #000000;}
.a-1-37-40     {color: #ffffff; background-color: #000000;}
.a-0-30-41     {color: #000000; background-color: #aa0000;}
.a-0-31-41     {color: #aa0000; background-color: #aa0000;}
.a-0-32-41     {color: #00aa00; background-color: #aa0000;}
.a-0-33-41     {color: #aaaa00; background-color: #aa0000;}
.a-0-34-41     {color: #0000aa; background-color: #aa0000;}
.a-0-35-41     {color: #aa00aa; background-color: #aa0000;}
.a-0-36-41     {color: #00aaaa; background-color: #aa0000;}
.a-0-37-41     {color: #aaaaaa; background-color: #aa0000;}
.a-1-30-41     {color: #444444; background-color: #aa0000;}
.a-1-31-41     {color: #ff4444; background-color: #aa0000;}
.a-1-32-41     {color: #44ff44; background-color: #aa0000;}
.a-1-33-41     {color: #ffff44; background-color: #aa0000;}
.a-1-34-41     {color: #4444ff; background-color: #aa0000;}
.a-1-35-41     {color: #ff44ff; background-color: #aa0000;}
.a-1-36-41     {color: #44ffff; background-color: #aa0000;}
.a-1-37-41     {color: #ffffff; background-color: #aa0000;}
.a-0-30-42     {color: #000000; background-color: #00aa00;}
.a-0-31-42     {color: #aa0000; background-color: #00aa00;}
.a-0-32-42     {color: #00aa00; background-color: #00aa00;}
.a-0-33-42     {color: #aaaa00; background-color: #00aa00;}
.a-0-34-42     {color: #0000aa; background-color: #00aa00;}
.a-0-35-42     {color: #aa00aa; background-color: #00aa00;}
.a-0-36-42     {color: #00aaaa; background-color: #00aa00;}
.a-0-37-42     {color: #aaaaaa; background-color: #00aa00;}
.a-1-30-42     {color: #444444; background-color: #00aa00;}
.a-1-31-42     {color: #ff4444; background-color: #00aa00;}
.a-1-32-42     {color: #44ff44; background-color: #00aa00;}
.a-1-33-42     {color: #ffff44; background-color: #00aa00;}
.a-1-34-42     {color: #4444ff; background-color: #00aa00;}
.a-1-35-42     {color: #ff44ff; background-color: #00aa00;}
.a-1-36-42     {color: #44ffff; background-color: #00aa00;}
.a-1-37-42     {color: #ffffff; background-color: #00aa00;}
.a-0-30-43     {color: #000000; background-color: #aaaa00;}
.a-0-31-43     {color: #aa0000; background-color: #aaaa00;}
.a-0-32-43     {color: #00aa00; background-color: #aaaa00;}
.a-0-33-43     {color: #aaaa00; background-color: #aaaa00;}
.a-0-34-43     {color: #0000aa; background-color: #aaaa00;}
.a-0-35-43     {color: #aa00aa; background-color: #aaaa00;}
.a-0-36-43     {color: #00aaaa; background-color: #aaaa00;}
.a-0-37-43     {color: #aaaaaa; background-color: #aaaa00;}
.a-1-30-43     {color: #444444; background-color: #aaaa00;}
.a-1-31-43     {color: #ff4444; background-color: #aaaa00;}
.a-1-32-43     {color: #44ff44; background-color: #aaaa00;}
.a-1-33-43     {color: #ffff44; background-color: #aaaa00;}
.a-1-34-43     {color: #4444ff; background-color: #aaaa00;}
.a-1-35-43     {color: #ff44ff; background-color: #aaaa00;}
.a-1-36-43     {color: #44ffff; background-color: #aaaa00;}
.a-1-37-43     {color: #ffffff; background-color: #aaaa00;}
.a-0-30-44     {color: #000000; background-color: #0000aa;}
.a-0-31-44     {color: #aa0000; background-color: #0000aa;}
.a-0-32-44     {color: #00aa00; background-color: #0000aa;}
.a-0-33-44     {color: #aaaa00; background-color: #0000aa;}
.a-0-34-44     {color: #0000aa; background-color: #0000aa;}
.a-0-35-44     {color: #aa00aa; background-color: #0000aa;}
.a-0-36-44     {color: #00aaaa; background-color: #0000aa;}
.a-0-37-44     {color: #aaaaaa; background-color: #0000aa;}
.a-1-30-44     {color: #444444; background-color: #0000aa;}
.a-1-31-44     {color: #ff4444; background-color: #0000aa;}
.a-1-32-44     {color: #44ff44; background-color: #0000aa;}
.a-1-33-44     {color: #ffff44; background-color: #0000aa;}
.a-1-34-44     {color: #4444ff; background-color: #0000aa;}
.a-1-35-44     {color: #ff44ff; background-color: #0000aa;}
.a-1-36-44     {color: #44ffff; background-color: #0000aa;}
.a-1-37-44     {color: #ffffff; background-color: #0000aa;}
.a-0-30-45     {color: #000000; background-color: #aa00aa;}
.a-0-31-45     {color: #aa0000; background-color: #aa00aa;}
.a-0-32-45     {color: #00aa00; background-color: #aa00aa;}
.a-0-33-45     {color: #aaaa00; background-color: #aa00aa;}
.a-0-34-45     {color: #0000aa; background-color: #aa00aa;}
.a-0-35-45     {color: #aa00aa; background-color: #aa00aa;}
.a-0-36-45     {color: #00aaaa; background-color: #aa00aa;}
.a-0-37-45     {color: #aaaaaa; background-color: #aa00aa;}
.a-1-30-45     {color: #444444; background-color: #aa00aa;}
.a-1-31-45     {color: #ff4444; background-color: #aa00aa;}
.a-1-32-45     {color: #44ff44; background-color: #aa00aa;}
.a-1-33-45     {color: #ffff44; background-color: #aa00aa;}
.a-1-34-45     {color: #4444ff; background-color: #aa00aa;}
.a-1-35-45     {color: #ff44ff; background-color: #aa00aa;}
.a-1-36-45     {color: #44ffff; background-color: #aa00aa;}
.a-1-37-45     {color: #ffffff; background-color: #aa00aa;}
.a-0-30-46     {color: #000000; background-color: #44ffff;}
.a-0-31-46     {color: #aa0000; background-color: #44ffff;}
.a-0-32-46     {color: #00aa00; background-color: #44ffff;}
.a-0-33-46     {color: #aaaa00; background-color: #44ffff;}
.a-0-34-46     {color: #0000aa; background-color: #44ffff;}
.a-0-35-46     {color: #aa00aa; background-color: #44ffff;}
.a-0-36-46     {color: #00aaaa; background-color: #44ffff;}
.a-0-37-46     {color: #aaaaaa; background-color: #44ffff;}
.a-1-30-46     {color: #444444; background-color: #44ffff;}
.a-1-31-46     {color: #ff4444; background-color: #44ffff;}
.a-1-32-46     {color: #44ff44; background-color: #44ffff;}
.a-1-33-46     {color: #ffff44; background-color: #44ffff;}
.a-1-34-46     {color: #4444ff; background-color: #44ffff;}
.a-1-35-46     {color: #ff44ff; background-color: #44ffff;}
.a-1-36-46     {color: #44ffff; background-color: #44ffff;}
.a-1-37-46     {color: #ffffff; background-color: #44ffff;}
.a-0-30-47     {color: #000000; background-color: #aaaaaa;}
.a-0-31-47     {color: #aa0000; background-color: #aaaaaa;}
.a-0-32-47     {color: #00aa00; background-color: #aaaaaa;}
.a-0-33-47     {color: #aaaa00; background-color: #aaaaaa;}
.a-0-34-47     {color: #0000aa; background-color: #aaaaaa;}
.a-0-35-47     {color: #aa00aa; background-color: #aaaaaa;}
.a-0-36-47     {color: #00aaaa; background-color: #aaaaaa;}
.a-0-37-47     {color: #aaaaaa; background-color: #aaaaaa;}
.a-1-30-47     {color: #444444; background-color: #aaaaaa;}
.a-1-31-47     {color: #ff4444; background-color: #aaaaaa;}
.a-1-32-47     {color: #44ff44; background-color: #aaaaaa;}
.a-1-33-47     {color: #ffff44; background-color: #aaaaaa;}
.a-1-34-47     {color: #4444ff; background-color: #aaaaaa;}
.a-1-35-47     {color: #ff44ff; background-color: #aaaaaa;}
.a-1-36-47     {color: #44ffff; background-color: #aaaaaa;}
.a-1-37-47     {color: #ffffff; background-color: #aaaaaa;}
.a5-0-30-40    {text-decoration: blink; color: #000000; background-color: #000000;}
.a5-0-31-40    {text-decoration: blink; color: #aa0000; background-color: #000000;}
.a5-0-32-40    {text-decoration: blink; color: #00aa00; background-color: #000000;}
.a5-0-33-40    {text-decoration: blink; color: #aaaa00; background-color: #000000;}
.a5-0-34-40    {text-decoration: blink; color: #0000aa; background-color: #000000;}
.a5-0-35-40    {text-decoration: blink; color: #aa00aa; background-color: #000000;}
.a5-0-36-40    {text-decoration: blink; color: #00aaaa; background-color: #000000;}
.a5-0-37-40    {text-decoration: blink; color: #aaaaaa; background-color: #000000;}
.a5-1-30-40    {text-decoration: blink; color: #444444; background-color: #000000;}
.a5-1-31-40    {text-decoration: blink; color: #ff4444; background-color: #000000;}
.a5-1-32-40    {text-decoration: blink; color: #44ff44; background-color: #000000;}
.a5-1-33-40    {text-decoration: blink; color: #ffff44; background-color: #000000;}
.a5-1-34-40    {text-decoration: blink; color: #4444ff; background-color: #000000;}
.a5-1-35-40    {text-decoration: blink; color: #ff44ff; background-color: #000000;}
.a5-1-36-40    {text-decoration: blink; color: #44ffff; background-color: #000000;}
.a5-1-37-40    {text-decoration: blink; color: #ffffff; background-color: #000000;}
.a5-0-30-41    {text-decoration: blink; color: #000000; background-color: #aa0000;}
.a5-0-31-41    {text-decoration: blink; color: #aa0000; background-color: #aa0000;}
.a5-0-32-41    {text-decoration: blink; color: #00aa00; background-color: #aa0000;}
.a5-0-33-41    {text-decoration: blink; color: #aaaa00; background-color: #aa0000;}
.a5-0-34-41    {text-decoration: blink; color: #0000aa; background-color: #aa0000;}
.a5-0-35-41    {text-decoration: blink; color: #aa00aa; background-color: #aa0000;}
.a5-0-36-41    {text-decoration: blink; color: #00aaaa; background-color: #aa0000;}
.a5-0-37-41    {text-decoration: blink; color: #aaaaaa; background-color: #aa0000;}
.a5-1-30-41    {text-decoration: blink; color: #444444; background-color: #aa0000;}
.a5-1-31-41    {text-decoration: blink; color: #ff4444; background-color: #aa0000;}
.a5-1-32-41    {text-decoration: blink; color: #44ff44; background-color: #aa0000;}
.a5-1-33-41    {text-decoration: blink; color: #ffff44; background-color: #aa0000;}
.a5-1-34-41    {text-decoration: blink; color: #4444ff; background-color: #aa0000;}
.a5-1-35-41    {text-decoration: blink; color: #ff44ff; background-color: #aa0000;}
.a5-1-36-41    {text-decoration: blink; color: #44ffff; background-color: #aa0000;}
.a5-1-37-41    {text-decoration: blink; color: #ffffff; background-color: #aa0000;}
.a5-0-30-42    {text-decoration: blink; color: #000000; background-color: #00aa00;}
.a5-0-31-42    {text-decoration: blink; color: #aa0000; background-color: #00aa00;}
.a5-0-32-42    {text-decoration: blink; color: #00aa00; background-color: #00aa00;}
.a5-0-33-42    {text-decoration: blink; color: #aaaa00; background-color: #00aa00;}
.a5-0-34-42    {text-decoration: blink; color: #0000aa; background-color: #00aa00;}
.a5-0-35-42    {text-decoration: blink; color: #aa00aa; background-color: #00aa00;}
.a5-0-36-42    {text-decoration: blink; color: #00aaaa; background-color: #00aa00;}
.a5-0-37-42    {text-decoration: blink; color: #aaaaaa; background-color: #00aa00;}
.a5-1-30-42    {text-decoration: blink; color: #444444; background-color: #00aa00;}
.a5-1-31-42    {text-decoration: blink; color: #ff4444; background-color: #00aa00;}
.a5-1-32-42    {text-decoration: blink; color: #44ff44; background-color: #00aa00;}
.a5-1-33-42    {text-decoration: blink; color: #ffff44; background-color: #00aa00;}
.a5-1-34-42    {text-decoration: blink; color: #4444ff; background-color: #00aa00;}
.a5-1-35-42    {text-decoration: blink; color: #ff44ff; background-color: #00aa00;}
.a5-1-36-42    {text-decoration: blink; color: #44ffff; background-color: #00aa00;}
.a5-1-37-42    {text-decoration: blink; color: #ffffff; background-color: #00aa00;}
.a5-0-30-43    {text-decoration: blink; color: #000000; background-color: #aaaa00;}
.a5-0-31-43    {text-decoration: blink; color: #aa0000; background-color: #aaaa00;}
.a5-0-32-43    {text-decoration: blink; color: #00aa00; background-color: #aaaa00;}
.a5-0-33-43    {text-decoration: blink; color: #aaaa00; background-color: #aaaa00;}
.a5-0-34-43    {text-decoration: blink; color: #0000aa; background-color: #aaaa00;}
.a5-0-35-43    {text-decoration: blink; color: #aa00aa; background-color: #aaaa00;}
.a5-0-36-43    {text-decoration: blink; color: #00aaaa; background-color: #aaaa00;}
.a5-0-37-43    {text-decoration: blink; color: #aaaaaa; background-color: #aaaa00;}
.a5-1-30-43    {text-decoration: blink; color: #444444; background-color: #aaaa00;}
.a5-1-31-43    {text-decoration: blink; color: #ff4444; background-color: #aaaa00;}
.a5-1-32-43    {text-decoration: blink; color: #44ff44; background-color: #aaaa00;}
.a5-1-33-43    {text-decoration: blink; color: #ffff44; background-color: #aaaa00;}
.a5-1-34-43    {text-decoration: blink; color: #4444ff; background-color: #aaaa00;}
.a5-1-35-43    {text-decoration: blink; color: #ff44ff; background-color: #aaaa00;}
.a5-1-36-43    {text-decoration: blink; color: #44ffff; background-color: #aaaa00;}
.a5-1-37-43    {text-decoration: blink; color: #ffffff; background-color: #aaaa00;}
.a5-0-30-44    {text-decoration: blink; color: #000000; background-color: #0000aa;}
.a5-0-31-44    {text-decoration: blink; color: #aa0000; background-color: #0000aa;}
.a5-0-32-44    {text-decoration: blink; color: #00aa00; background-color: #0000aa;}
.a5-0-33-44    {text-decoration: blink; color: #aaaa00; background-color: #0000aa;}
.a5-0-34-44    {text-decoration: blink; color: #0000aa; background-color: #0000aa;}
.a5-0-35-44    {text-decoration: blink; color: #aa00aa; background-color: #0000aa;}
.a5-0-36-44    {text-decoration: blink; color: #00aaaa; background-color: #0000aa;}
.a5-0-37-44    {text-decoration: blink; color: #aaaaaa; background-color: #0000aa;}
.a5-1-30-44    {text-decoration: blink; color: #444444; background-color: #0000aa;}
.a5-1-31-44    {text-decoration: blink; color: #ff4444; background-color: #0000aa;}
.a5-1-32-44    {text-decoration: blink; color: #44ff44; background-color: #0000aa;}
.a5-1-33-44    {text-decoration: blink; color: #ffff44; background-color: #0000aa;}
.a5-1-34-44    {text-decoration: blink; color: #4444ff; background-color: #0000aa;}
.a5-1-35-44    {text-decoration: blink; color: #ff44ff; background-color: #0000aa;}
.a5-1-36-44    {text-decoration: blink; color: #44ffff; background-color: #0000aa;}
.a5-1-37-44    {text-decoration: blink; color: #ffffff; background-color: #0000aa;}
.a5-0-30-45    {text-decoration: blink; color: #000000; background-color: #aa00aa;}
.a5-0-31-45    {text-decoration: blink; color: #aa0000; background-color: #aa00aa;}
.a5-0-32-45    {text-decoration: blink; color: #00aa00; background-color: #aa00aa;}
.a5-0-33-45    {text-decoration: blink; color: #aaaa00; background-color: #aa00aa;}
.a5-0-34-45    {text-decoration: blink; color: #0000aa; background-color: #aa00aa;}
.a5-0-35-45    {text-decoration: blink; color: #aa00aa; background-color: #aa00aa;}
.a5-0-36-45    {text-decoration: blink; color: #00aaaa; background-color: #aa00aa;}
.a5-0-37-45    {text-decoration: blink; color: #aaaaaa; background-color: #aa00aa;}
.a5-1-30-45    {text-decoration: blink; color: #444444; background-color: #aa00aa;}
.a5-1-31-45    {text-decoration: blink; color: #ff4444; background-color: #aa00aa;}
.a5-1-32-45    {text-decoration: blink; color: #44ff44; background-color: #aa00aa;}
.a5-1-33-45    {text-decoration: blink; color: #ffff44; background-color: #aa00aa;}
.a5-1-34-45    {text-decoration: blink; color: #4444ff; background-color: #aa00aa;}
.a5-1-35-45    {text-decoration: blink; color: #ff44ff; background-color: #aa00aa;}
.a5-1-36-45    {text-decoration: blink; color: #44ffff; background-color: #aa00aa;}
.a5-1-37-45    {text-decoration: blink; color: #ffffff; background-color: #aa00aa;}
.a5-0-30-46    {text-decoration: blink; color: #000000; background-color: #44ffff;}
.a5-0-31-46    {text-decoration: blink; color: #aa0000; background-color: #44ffff;}
.a5-0-32-46    {text-decoration: blink; color: #00aa00; background-color: #44ffff;}
.a5-0-33-46    {text-decoration: blink; color: #aaaa00; background-color: #44ffff;}
.a5-0-34-46    {text-decoration: blink; color: #0000aa; background-color: #44ffff;}
.a5-0-35-46    {text-decoration: blink; color: #aa00aa; background-color: #44ffff;}
.a5-0-36-46    {text-decoration: blink; color: #00aaaa; background-color: #44ffff;}
.a5-0-37-46    {text-decoration: blink; color: #aaaaaa; background-color: #44ffff;}
.a5-1-30-46    {text-decoration: blink; color: #444444; background-color: #44ffff;}
.a5-1-31-46    {text-decoration: blink; color: #ff4444; background-color: #44ffff;}
.a5-1-32-46    {text-decoration: blink; color: #44ff44; background-color: #44ffff;}
.a5-1-33-46    {text-decoration: blink; color: #ffff44; background-color: #44ffff;}
.a5-1-34-46    {text-decoration: blink; color: #4444ff; background-color: #44ffff;}
.a5-1-35-46    {text-decoration: blink; color: #ff44ff; background-color: #44ffff;}
.a5-1-36-46    {text-decoration: blink; color: #44ffff; background-color: #44ffff;}
.a5-1-37-46    {text-decoration: blink; color: #ffffff; background-color: #44ffff;}
.a5-0-30-47    {text-decoration: blink; color: #000000; background-color: #aaaaaa;}
.a5-0-31-47    {text-decoration: blink; color: #aa0000; background-color: #aaaaaa;}
.a5-0-32-47    {text-decoration: blink; color: #00aa00; background-color: #aaaaaa;}
.a5-0-33-47    {text-decoration: blink; color: #aaaa00; background-color: #aaaaaa;}
.a5-0-34-47    {text-decoration: blink; color: #0000aa; background-color: #aaaaaa;}
.a5-0-35-47    {text-decoration: blink; color: #aa00aa; background-color: #aaaaaa;}
.a5-0-36-47    {text-decoration: blink; color: #00aaaa; background-color: #aaaaaa;}
.a5-0-37-47    {text-decoration: blink; color: #aaaaaa; background-color: #aaaaaa;}
.a5-1-30-47    {text-decoration: blink; color: #444444; background-color: #aaaaaa;}
.a5-1-31-47    {text-decoration: blink; color: #ff4444; background-color: #aaaaaa;}
.a5-1-32-47    {text-decoration: blink; color: #44ff44; background-color: #aaaaaa;}
.a5-1-33-47    {text-decoration: blink; color: #ffff44; background-color: #aaaaaa;}
.a5-1-34-47    {text-decoration: blink; color: #4444ff; background-color: #aaaaaa;}
.a5-1-35-47    {text-decoration: blink; color: #ff44ff; background-color: #aaaaaa;}
.a5-1-36-47    {text-decoration: blink; color: #44ffff; background-color: #aaaaaa;}
.a5-1-37-47    {text-decoration: blink; color: #ffffff; background-color: #aaaaaa;}
