package Devel::Spy::TieArray;
use strict;
use warnings;
use Tie::Scalar;
our @ISA = 'Tie::Scalar';
use constant { PAYLOAD => 0, CODE => 1 };

sub TIEARRAY {
    my $class = shift @_;

    return bless [@_], $class;
}

sub FETCH {
    my ( $self, $ix ) = @_;
    my $followup = $self->[CODE]->(" ->[$ix]");
    my $value    = $self->[PAYLOAD]->[$ix];
    $followup = $followup->(" ->$value");
    return Devel::Spy->new( $value, $followup );
}

sub STORE {
    my ( $self, $ix, $value ) = @_;
    my $followup = $self->[CODE]->(" ->[$ix] = $value");
    $self->[PAYLOAD]->[$ix] = $value;
    return Devel::Spy->new( $value, $followup );
}

sub FETCHSIZE {
    my $self     = shift @_;
    my $followup = $self->[CODE]->(' scalar(@...)');
    my $value    = scalar @{ $self->[PAYLOAD] };
    $followup = $self->[CODE]->(" ->$value");
    return Devel::Spy->new( $value, $followup );
}

sub STORESIZE {
    my ( $self, $count ) = @_;
    $self->[CODE]->(" \$\#... = $count");
    $#{ $self->[PAYLOAD] } = 1 + $count;
    return;
}

# sub EXTEND {
#     my ( $self, $count ) = @_;
#
# }
#
# sub EXISTS {
#
# }
#
# sub DELETE { }
#
# sub CLEAR { }
#
# sub PUSH { }
#
# sub POP { }
#
# sub SHIFT   { }
# sub UNSHIFT { }
# sub SPLICE  { }

1;

__END__

=head1 NAME

Devel::Spy::TieArray - Tied logging wrapper for arrays

=head1 SYNOPSIS

  tie my @pretend_guts, 'Devel::Spy::TieArray', \ @real_guts, $logging_function
    or croak;

  # Passed operation through to @real_guts and tattled about the
  # operation to $logging_function.
  $pretend_guts[0] = 42;

=head1 CAVEATS

This has not been implemented. Feel free to add more and send me
patches. I'll also grant you permission to upload into the Devel::Spy
namespace if you're a clueful developer.

=head1 SEE ALSO

L<Devel::Spy>, L<Devel::Spy::_obj>, L<Devel::Spy::Util>,
L<Devel::Spy::TieHash>, L<Devel::Spy::TieScalar>,
L<Devel::Spy::TieHandle>.
