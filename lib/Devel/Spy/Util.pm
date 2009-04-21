package Devel::Spy::Util;
use strict;
use warnings;

use overload     ();
use Scalar::Util ();
use Carp         ();

sub Y (&) {    ## no critic (Prototype)
               # The Y combinator.
    my $curried_rec = shift @_;
    my $p = sub {
        my $f = shift @_;
        return $curried_rec->( sub { $f->($f)->(@_) } );
    };
    return $p->($p);
}

sub compile_this {

    # Accepts some source code and expects to return a true
    # value. Devel::Spy::_obj uses this to compile a bunch of subs but
    # without having to repeat the "eval or croak" stuff all over the
    # place.
    #
    # Example:
    #   my $sub = Devel::Spy::Util::compile_this( <<"SRC" );
    #       sub ... {
    #           ...
    #       };
    #       1;
    #   SRC
    my $src = shift @_;
    my ( $package, $filename, $line ) = caller;

    # Add some sugar to make the code appear in the proper location.
    $src = <<"CODE";
#line @{[$line]} "@{[$filename]}"
package $package;
$src
CODE

    ## no critic (Eval)
    if (wantarray) {
        my @result = eval $src
            or Carp::confess "$@ while compiling:\n$src";
        return @result;
    }
    else {
        my $result = eval $src
            or Carp::confess "$@ while compiling:\n$src";
        return $result;
    }

    # NOT REACHED
}

sub comes_from {

    # Returns a string showing the location of the non-Devel::Spy code
    # that's higher in the call stack.
    my $cx = 1;
    while ( my ( $pkg, undef, $line ) = caller $cx++ ) {

        # Find !Devel::Spy
        unless ( $pkg =~ /^Devel::Spy/ ) {
            return "($pkg:$line)";
        }
    }

    # Huh? I suppose this only occurs if Devel::Spy is the *only*
    # thing in the call stack and I'm not even sure how that happens.
    return;
}

sub wrap_thing {
    my ( $thing, $code ) = @_;

    # Use a tied proxy to $thing instead of $thing directly. But only
    # if $thing is a reference.
    my $reftype = Scalar::Util::reftype $thing;
    return $thing unless defined $reftype;

    # Return a tied wrapper over $thing.
    if ( 'HASH' eq $reftype ) {
        tie my %pretend_self, 'Devel::Spy::TieHash', $thing, $code
            or Carp::confess;
        return \%pretend_self;
    }
    elsif ( 'SCALAR' eq $reftype ) {
        tie my $pretend_self, 'Devel::Spy::TieScalar', $thing, $code
            or Carp::confess;
        return \$pretend_self;
    }

    # Missing implementations for TIEARRAY and TIEHANDLE.
    Carp::croak "Unsupported reftype: $reftype on "
        . overload::StrVal($thing);
}

1;

__END__

=head1 NAME

Devel::Spy::Util - Utility functions for Devel::Spy

=head1 PRIVATE FUNCTIONS

=over

=item C<FUNCTION = Devel::Spy::Y { ... }>

=item C<FUNCTION = &Devel::Spy::Y( sub { ... } )>

The Y combinator. See http://use.perl.org/~Aristotle/journal/30896 for
the scoop. Devel::Spy uses it to make functions that support the
following snippet.

  while ( ... ) {
      $logger = $logger->();
  }

=item C<VALUE = compile_this( SOURCE CODE )>

Compiles SOURCE CODE and returns it. It throws an exception if the
result is false.

=item C<LOCATION = comes_from()>

Returns a string showing the file and line number that called into
Devel::Spy.

=item C<WRAPPED OBJECT = wrap_thing( OBJECT, CODE )>

=item C<WRAPPED OBJECT = wrap_thing( REFERENCE, CODE )>

=item C<VALUE = wrap_thing( VALUE, CODE )>

If the "thing" passed in as the first parameter is any kind of
reference or object it is returned in a Devel::Spy::Tie* wrapper.

This is how Devel::Spy tracks accesses to hashes and other references.

=item SEE ALSO

L<Devel::Spy>, L<Devel::Spy::_obj>, L<Devel::Spy::TieHash>,
L<Devel::Spy::TieArray>, L<Devel::Spy::TieScalar>,
L<Devel::Spy::TieHandle>

=back
