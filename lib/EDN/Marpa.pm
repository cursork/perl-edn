# vim:set foldmethod=marker:
use v5.010;
use warnings;

use Data::Dumper;

package EDN::Marpa;

use Marpa::R2;

# Grammar: Initial version based on: https://gist.github.com/bjeanes/4718964
my $raw_grammar = <<'BNF'; #{{{1
:default ::= action => ::first
:start ::= EDN
EDN ::= Nil | Boolean | Vector

:discard ~ whitespace
whitespace ~ [\s,]+

Nil ::= 'nil' action => nil
Boolean ::= 'true'  action => boolean
          | 'false' action => boolean

EDN_many ::= EDN | EDN EDN_many action => cons

Vector ::= '[]' action => empty_vector
         | '[' EDN_many ']' action => vector
BNF
# }}}1

# Original Grammer from URL: {{{1
=cut
EDN ::= Whitespace (Comment | (Discard Whitespace)? (Tag Whitespace)? (List | Vector | Map | Set | String | Number | Keyword | Symbol | Nil | Boolean | Char) Whitespace Comment?)
 
Nil ::= "nil"
True ::= "true"
False ::= "false"
Boolean ::= True | False
Symbol ::= (Namespace "/")? ("/" | (Alphabetic Alphanumeric*)? (("-" | "." | "+")? Alphabetic | ("*" | "!" | "_" | "?" | "$" | "%" | "&" | "=")) (Alphanumeric | "#" | ":")*) /* FIXME: very inaccurate */
Keyword ::= ":" Symbol
 
/* Whitespace */
Whitespace ::= (Space | Tab | Comma)*
Space ::= " "
Tab ::= "\t"
Comma ::= ","
 
/* Data Structures */
List ::= "(" EDN* ")"
Vector ::= "[" EDN* "]"
Map ::= "{" (EDN EDN)* "}"
Set ::= "#{" EDN* "}"                                          /* TODO: duplicate semantics */
String ::= '"' UTF8Char* '"'                                 /* TODO: define UTF8Char — handle escaping */
Character ::= "\" (Alphabetic | "newline" | "tab" | "return" | "space") /* numbers? */
 
/* Numbers */
NonZeroDigit ::= "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
ZeroDigit ::= "0"
Digit ::= ZeroDigit | NonZeroDigit
Digits ::= ZeroDigit | (NonZeroDigit Digit*)
Integer ::= Digits "N"?                                      /* depends on https://github.com/edn-format/edn/issues/33 */
Float ::= Digits ("M" | (Digits (Fraction | (Fraction? Exponent)) "M"?))
Fraction ::= "." Digit+
Exponent ::= ("e" | "E") Sign? Digits
Sign ::= "+" | "-"
Number ::= Sign? (Integer | Float)
 
/* Misc */
Comment ::= ";" UTF8Char* NewLine
NewLine ::= "\r\n" | "\n" | "\r"
UpperAlphabetic ::= "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z"
LowerAlphabetic ::= "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z"
Alphabetic ::= UpperAlphabetic | LowerAlphabetic
Namespace ::= LowerAlphabetic+ ("." LowerAlphabetic+)*
Tag ::= "#" (Namespace "/") Alphabetic+
Discard ::= "#_"
=cut
# }}}1

my $grammar = Marpa::R2::Scanless::G->new({ source => \$raw_grammar });
my $recce   = Marpa::R2::Scanless::R->new({ grammar => $grammar, semantics_package => 'EDN::Marpa::Semantics'
	, trace_terminals => 1
});

sub do_it {
	my ($input) = @_;
	$recce->read( \$input );

	my $value_ref = $recce->value;
	my $value = $value_ref ? ${$value_ref} : 'No Parse';
	return $value;
}

package EDN::Marpa::Semantics;

sub nil          { EDN::Marpa::Semantics::Nil->new }
sub boolean      { EDN::Marpa::Semantics::Boolean->new(truth => ($_[1] eq 'true')) }
sub empty_vector { [] }
sub vector       { shift, shift and pop; return shift; } # Already constructed by EDN many into an array ref
sub whitespace   { EDN::Marpa::Semantics::Whitespace->new(chars => $_[1]) }
sub cons         {
	my (undef, $car, $cdr) = @_;
	$cdr = [$cdr] unless ref $cdr eq 'ARRAY';
	[$car, @$cdr];
}

package EDN::Marpa::Semantics::Nil;
use Moo;

package EDN::Marpa::Semantics::Whitespace;
use Moo;

has chars => (is => 'ro');

package EDN::Marpa::Semantics::Boolean;
use Moo;

has truth => (is => 'ro');

package main;

my $parsed = EDN::Marpa::do_it('[true false true true false nil]');
say '-------';
say Data::Dumper->Dump([$parsed]);

__END__

=head1 NAME

EDN::Marpa - Marpa-based processing of edn

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS
