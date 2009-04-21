package Devel::Spy::TieHash;
use strict;
use warnings;
use Tie::Hash ();
our @ISA = 'Tie::Hash';
use Carp 'carp';

use constant { PAYLOAD => 0, CODE => 1, };

sub TIEHASH {
    my $class = shift @_;

    my @self;
    @self[ PAYLOAD, CODE, ] = @_;

    return bless \@self, $class;
}

sub FETCH {
    my ( $self, $key ) = @_;
    unless ( defined $key ) {
        $key = '';
        carp 'Use of uninitialized value in hash key';
    }

    my $value = $self->[PAYLOAD]->{$key};

    my $followup = $self->[CODE]
        ->( "->{$key} -> " . ( defined $value ? $value : 'undef' ) );

    return Devel::Spy->new( $value, $followup );
}

sub STORE {
    my ( $self, $key, $value ) = @_;
    unless ( defined $key ) {
        $key = '';
        carp 'Use of uninitialized value in hash key';
    }

    $self->[PAYLOAD]->{$key} = $value;

    my $followup = $self->[CODE]
        ->( "->{$key} = " . ( defined $value ? $value : 'undef' ) );

    return Devel::Spy->new( $value, $followup );
}

1;

__END__

=head1 NAME

Devel::Spy::TieHash - Tied logging wrapper for hashes

=head1 SYNOPSIS

  tie my %pretend_guts, 'Devel::Spy::TieHash', \ %real_guts, $logging_function
    or croak;

  # Passed operation through to %real_guts and tattled about the
  # operation to $logging_function.
  $pretend_guts{foo} = 42;

=head1 CAVEATS

Most functions have not been implemented. I implemented only the ones
I needed. Feel free to add more and send me patches. I'll also grant
you permission to upload into the Devel::Spy namespace if you're a
clueful developer.

=head1 SEE ALSO

L<Devel::Spy>, L<Devel::Spy::_obj>, L<Devel::Spy::Util>,
L<Devel::Spy::TieArray>, L<Devel::Spy::TieScalar>,
L<Devel::Spy::TieHandle>.
