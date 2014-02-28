use v5.010;
use warnings;

use Test::Most;

use EDN::Marpa;

sub parsed_is ($$$) {
	my ($edn, $expected, $label) = @_;
	is_deeply(EDN::Marpa::parse($edn), $expected, $label);
}

sub nil()   { EDN::Marpa::Semantics::Nil->new }
sub true()  { EDN::Marpa::Semantics::Boolean->new(truth => 1) }
sub false() { EDN::Marpa::Semantics::Boolean->new(truth => '') }

# Nil and bool
parsed_is('nil',   nil,   'Nil');
parsed_is('true',  true,  'true');
parsed_is('false', false, 'false');

parsed_is('[]', [], 'Empty vector');
parsed_is('[true true false]', [true, true, false], 'TTF vector');

parsed_is('{}', {}, 'Empty hash');
parsed_is('{ true false, false true }', {1 => '', '' => 1}, 'True is false and false is true (hashmap)');

parsed_is '123',  123, 'Basic integer';
parsed_is '123N', 123, '\'N\' integer';

done_testing;
