
use strict;
use warnings;

use Test::More tests => 10;

require_ok('Mixin::ExtraFields::Hive');

use lib 't/lib';

my $test_class;

BEGIN {
  $test_class = 'Object::HasHive';
  use_ok($test_class);
}

my $object = $test_class->new;

isa_ok($object, $test_class);

can_ok(
  $object,
  qw(hive nest),
);

is(
  $object->hive->foo->bar->baz->GET,
  undef,
  "no defined foo.bar.baz entry yet",
);

$object->hive->foo->bar->baz->SET(10);

is(
  $object->hive->foo->bar->baz->GET,
  10,
  "we set foo.bar.baz to 10 and it stuck",
);

is(
  $object->nest->foo->bar->baz->GET,
  undef,
  "but that was the hive; the nest is empty :(",
);

$object->nest->foo->bar->baz->SET(20);

is(
  $object->nest->foo->bar->baz->GET,
  20,
  "we set nest/foo.bar.baz to 20 and it stuck",
);

is(
  $object->hive->foo->bar->baz->GET,
  10,
  "but the hive's foo.bar.baz is still 10",
);

$object->_empty_hive;

is(
  $object->hive->foo->bar->baz->GET,
  undef,
  "after emptying the hive, there's nothing there again",
);
