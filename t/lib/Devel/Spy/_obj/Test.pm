package Devel::Spy::_obj::Test;
use strict;
use warnings;
use Test::Class;
BEGIN { our @ISA = 'Test::Class' }
use Test::More;
use Scalar::Util qw( reftype blessed );
use Devel::Spy;
use lib grep {-d} qw( t/lib ../t/lib lib );
use NSA;    # from t/lib

sub overload : Test(6) {
    my $value = 42;

    my $obj = Devel::Spy->new( $value, Devel::Spy->make_null_eventlog );
    ok( scalar overload::Overloaded($obj),
        overload::StrVal($obj) . ' is overloaded'
    );

    ok( overload::Method( $obj, $_ ), "$_ operator is overloaded" )
        for split ' ', $overload::ops{dereferencing};
}

sub tied_hash : Test(5) {
    my $guts = {};
    my $obj  = Devel::Spy->new( $guts, Devel::Spy->make_null_eventlog );

    my $thing = do {

        package Devel::Spy::_obj;
        $obj->[Devel::Spy::UNTIED_PAYLOAD];
    };

    ok( !overload::Method( $thing, '%{}' ), q[Payload isn't overloaded] );
    ok( overload::Method( $obj, '%{}' ), q[Wrapper overloads %{}] );

    # These tests will fail with pseudo-hash errors if $thing isn't
    # properly blessed.
TODO: {
        local $TODO = q['' is returned instead];
        is( $obj->{foo}, undef, q[Uninitialized hash entries are undef] );
    }
    is( 0 + ( $obj->{foo} = 42 ), 42, q[Values can be stored] );
    is( 0 + $obj->{foo}, 42, q[Values can be retrieved] );
}

sub method : Test(1) {
    my ( $log, $logger ) = Devel::Spy->make_eventlog;

    # Snoop on the NSA.
    my $nsa = Devel::Spy->new( NSA->new, $logger );

    my $bitbucket = !!$nsa->phone;

    like( "@$log", qr/^ \$->phone\(\) ->Hello from the NSA! ->bool/m );
}
1;
