package Devel::Spy::TieScalar::Test;
use strict;
use warnings;
use Test::Class;
BEGIN { our @ISA = 'Test::Class' }
use Test::More;

use Devel::Spy;

sub value : Test(8) {
    my @log;
    my $logger;
    $logger = sub { push @log, "@_"; return $logger };

    my $inside;
    isa_ok( tie( my $outside, 'Devel::Spy::TieScalar', \$inside, $logger ),
        'Devel::Spy::TieScalar', 'tie' );

    is( tied($outside)->[Devel::Spy::TieScalar::PAYLOAD],
        \$inside, 'Found wrapped variable inside wrapper' );

    local $" = "\n";
    is( "@log", '', 'Log is empty' );

    is( $inside, undef, 'Storage is initially unchanged' );

    $outside = 42;
    is( $inside, 42, 'Stored 42 ok' );
    like( "@log", qr/^= 42/m, 'Log reflects the STORE' );

    is( $outside, 42, 'Fetched 42 ok' );
    like( "@log", qr/^-> 42/m, 'Log reflects the fetch' );
}

1;
