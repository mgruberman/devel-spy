package Devel::Spy::TieArray;
use strict;
use warnings;
use Tie::Scalar;
our @ISA = 'Tie::Scalar';

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
