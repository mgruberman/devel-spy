use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Devel::Spy',
    AUTHOR        => 'Joshua ben Jore <jjore@cpan.org>',
    VERSION_FROM  => 'lib/Devel/Spy.pm',
    ABSTRACT_FROM => 'lib/Devel/Spy.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'     => 0,
        'Test::Class'    => 0,
        'Test::Warn'     => 0,
        'UNIVERSAL::ref' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Devel-Spy-*' },
);
