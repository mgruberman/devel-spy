package Devel::Spy::TieHash::Test;
use strict;
use warnings;
use Test::Class;
BEGIN { our @ISA = 'Test::Class' }
use Test::More;
use Test::Warn;

use Devel::Spy;

sub value : Test(8) {
    my @log;
    my $logger;
    $logger = sub { push @log, "@_"; return $logger };

    my %inside;
    isa_ok( tie( my %outside, 'Devel::Spy::TieHash', \%inside, $logger ),
        'Devel::Spy::TieHash', 'tie' );

    is( tied(%outside)->[Devel::Spy::TieHash::PAYLOAD],
        \%inside, 'Found wrapped variable inside wrapper' );

    local $" = "\n";
    is( "@log", '', 'Log is empty' );

    is( keys(%inside), 0, 'Storage is initially unchanged' );

    $outside{foo} = 42;
    is( $inside{foo}, 42, 'Wrapped hash got assignment' );
    like( "@log", qr/^->{foo} = 42/m, 'Log reflects the STORE' );

    is( $outside{foo}, 42, 'Wrapper reflects the assignment' );
    like( "@log", qr/^->{foo} -> 42/m, 'Log reflects the fetch' );
}

# sub undef : Test(2) {
#     my ( undef, $logger ) = Devel::Spy->make_eventlog;
#
#     my $x = Devel::Spy->new( {}, $logger );
#     warning_like { my $y = $x->{ undef() } } qr/uninitialized/;
#     warning_like { $x->{ undef() } = 42 } qr/uninitialized/;
# }

1;
