#!perl -wT
use strict;
use warnings;
use lib grep -d, qw( t/lib lib ../lib );

use Devel::Spy::Test;
use Devel::Spy::_obj::Test;
use Devel::Spy::Util::Test;
use Devel::Spy::TieHash::Test;
use Devel::Spy::TieArray::Test;
use Devel::Spy::TieScalar::Test;
use Devel::Spy::TieHandle::Test;

Test::Class->runtests;
