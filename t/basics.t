use v5.010;
use warnings;

use Test::Most;

use EDN::Marpa;

is_deeply(EDN::Marpa::parse('[]'), [], 'Empty vector');

done_testing;
