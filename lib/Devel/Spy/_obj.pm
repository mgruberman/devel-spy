package Devel::Spy::_obj;
use strict;
use warnings;

## WARNING!!!! HEY!! Read this!

# This package should be as spotless as possible. Don't define or
# import any functions here because then they'll shadow that if it's
# also defined in the objects that are being wrapped.

# Seriously. Make recursion fatal. I hit this alot when writing this
# kind of code and it helps to have a backstop.
use warnings FATAL => 'all';

use overload ();
use Devel::Spy::Util;

# Overload all dereferencing.
use overload(
    map {
        my $deref = $_;
        $deref => Devel::Spy::Util->compile_this( <<"CODE" );
            sub {
                local *__ANON__ = __PACKAGE__ . '->$deref';

                # Allow ourselves to access our own guts and let everyone
                # else have the payload.
                if ( caller() eq 'Devel::Spy::_obj' ) {
                    return \$_[0];
                }
                else {
                    # This idea is really dodgy but I found myself in
                    # an infinite loop of some kind when I returned a
                    # plain Devel::Spy object wrapping the
                    # result. Bummer.
                    my \$followup = \$_[0][Devel::Spy::CODE]->( ' ->$deref' );
                    tied( %{ \$_[0][Devel::Spy::TIED_PAYLOAD] } )->[1] = \$followup;
                    return \$_[0][Devel::Spy::TIED_PAYLOAD];
                }
            }
CODE
        }
        split ' ',
    $overload::ops{dereferencing}
);

# For conversion ops, just return the payload.
use overload(
    map {
        my $converter = $_;
        $converter => Devel::Spy::Util->compile_this( <<"CODE" );
            sub {
                local *__ANON__ = __PACKAGE__ . '->$converter';

                \$_[0][Devel::Spy::CODE]->(' ->$converter');
                return \$_[0][Devel::Spy::TIED_PAYLOAD];
            }
CODE
        }
        split ' ',
    $overload::ops{conversion}
);

# Do a common things for all these common operators.
use overload(
    map {
        my $op = $_;
        $op => Devel::Spy::Util->compile_this( <<"CODE" );
            sub {
                local *__ANON__ = __PACKAGE__ . '->$op';

                # Unpack the arguments.
                my ( \$self, \$rhs, \$inverted ) = \@_;
                my \$orig_rhs = \$rhs;
                my \$lhs = \$self->[Devel::Spy::TIED_PAYLOAD];
                ( \$rhs, \$lhs ) = ( \$lhs, \$rhs ) if \$inverted;

                my \$result = \$lhs $op \$rhs;

                my \$followup = \$_[0][Devel::Spy::CODE]->(  ' ->('
                                                           . ( defined \$lhs ? \$lhs : 'undef')
                                                           . ' $op '
                                                           . ( defined \$rhs ? \$rhs : 'undef')
                                                           . ') ->'
                                                           . overload::StrVal(\$result) );
                return Devel::Spy->new( \$result, \$followup );
             };
CODE
        }
        map split(' '),
    @overload::ops{
        qw(with_assign num_comparison 3way_comparison str_comparison binary)}
);

# Shadow both isa and can methods. I want to make sure other things
# like overload.pm can still make requests about the Devel::Spy::_obj
# class with ->isa and ->can but any request about an object get
# forwarded to the inner, wrapped object.
for my $method (qw( isa can )) {
    my $src = <<"CODE";
#line @{[__LINE__]} "@{[__FILE__]}"
        sub $method {
            my \$self = shift \@_;

            if ( defined Scalar::Util::blessed( \$self ) ) {
                my \$followup = \$self->[Devel::Spy::CODE]->( '->$method' );
                # Object method call passed onto our stored thing.
                return Devel::Spy->new( \$self->[Devel::Spy::UNTIED_PAYLOAD]->$method( \@_ ),
                                        \$followup );
            }
            else {
                # Class method call on Devel::Spy::_obj. Just forward
                # to UNIVERSAL or whatever else is there.
                return \$self->SUPER::$method( \@_ );
            }
        };
        1;
CODE
    ## no critic (Eval)
    eval $src
        or Carp::croak "$@ while compiling: $src";
}

# Do all the proxy work for methods (other than isa and can) here.
use vars '$AUTOLOAD';

sub AUTOLOAD {
    my $method = $AUTOLOAD;
    $method =~ s/^Devel::Spy::_obj:://;

    my $self  = shift @_;
    my $class = Scalar::Util::blessed( $self->[Devel::Spy::UNTIED_PAYLOAD] );

    # Redispatch and log, maintaining context.
    if (wantarray) {

        # Log before.
        my $followup = $self->[Devel::Spy::CODE]->( " \@->$method("
                . join( ',', map overload::StrVal($_), @_ )
                . ')' );

        # Redispatch.
        my @results = $self->[Devel::Spy::UNTIED_PAYLOAD]->$method(@_);

        # Log after.
        $followup = $followup->(
            ' ->(' . join( ',', map overload::StrVal($_), @results ) . ')' );

        return @results;
    }
    elsif ( defined wantarray ) {

        # Log before.
        my $followup = $self->[Devel::Spy::CODE]->( " \$->$method("
                . join( ',', map overload::StrVal($_), @_ )
                . ')' );

        # Redispatch.
        my $result = $self->[Devel::Spy::UNTIED_PAYLOAD]->$method(@_);

        # Log after.
        $followup = $followup->( ' ->' . overload::StrVal($result) );

        return Devel::Spy->new( $result, $followup );
    }
    else {

        # Log before.
        my $followup = $self->[Devel::Spy::CODE]->( " V->$method("
                . join( ',', map overload::StrVal($_), @_ )
                . ')' );

        # Redispatch.
        $self->[Devel::Spy::UNTIED_PAYLOAD]->$method(@_);

        # Log after?

        return;
    }
}

sub DESTROY { }

1;

__END__

=head1 NAME

Devel::Spy::_obj - Devel::Spy implementation

=head1 SEE ALSO

L<Devel::Spy>, L<Devel::Spy::Util>, L<Devel::Spy::TieHash>,
L<Devel::Spy::TieArray>, L<Devel::Spy::TieScalar>,
L<Devel::Spy::TieHandle>
