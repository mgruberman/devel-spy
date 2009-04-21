package NSA;

sub new {
    my $class = shift @_;
    return bless {}, $class;
}

sub phone {
    return 'Hello from the NSA!';
}

1;
