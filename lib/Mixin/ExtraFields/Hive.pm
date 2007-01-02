
use strict;
use warnings;

package Mixin::ExtraFields::Hive;
use base qw(Mixin::ExtraFields);

=head1 NAME

Mixin::ExtraFields::Hive - infest your objects with hives

=head1 VERSION

version 0.002

 $Id: Hive.pm 26822 2007-01-02 21:45:45Z rjbs $

=cut

our $VERSION = '0.002';

=head1 SYNOPSIS

  use Mixin::ExtraFields::Hive -hive => {
    moniker => 'registry',
    driver  => 'DBI',
  };

=head1 DESCRIPTION

This module provides a Data::Hive to other classes' objects as a mix-in,
powered by Mixin::ExtraFields.  It behaves like Mixin::ExtraFields, but
generates a different set of methods.  It can use any Mixin::ExtraFields
driver.

=head1 GENERATED METHODS

=head2 hive

The main export of this module is the C<hive> method, generated by importing
the C<-hive> group.  The method will be imported under the moniker given to the
C<hive> group.  If this all sounds like Greek, you should probably re-read the
L<Mixin::ExtraFields> documentation.  As a simple example, however, the code in
the L</Synopsis>, above, would generate a C<registry> method instead of a
C<hive> method.

This method will return a L<Data::Hive> object for extra fields for the object
on which it's called.  At present, the Data::Hive object is recreated for each
call to the C<hive> method.  In the future, it will be possible to cache these
on the object or in some other manner.

=head2 other methods

At present, two support methods are installed by this mixin.  These methods may
go away in the future, when a more purpose-built subclass of Data::Hive::Store
is used.

These methods are:

  _mutate_hive - acts as a combined get/set extra accessor
  _exists_hive - acts as the standard exists_extra method
  _empty_hive  - deletes all hive data

=cut

use Data::Hive;
use Data::Hive::Store::Param;

# I wish this was easier. -- rjbs, 2006-12-09
use Sub::Exporter -setup => {
  groups => [ hive => \'gen_fields_group', ],
};

sub default_moniker { 'hive' }

sub methods { qw(hive mutate exists empty) }

sub _build_mutate_method {
  my ($self, $arg) = @_;

  my $id_method = $arg->{id_method};
  my $driver    = $arg->{driver};
  my $driver_set = $self->driver_method_name('set');
  my $driver_get = $self->driver_method_name('get');

  return sub {
    my $self = shift;
    my $name = shift;
    my $id = $self->$$id_method;

    if (@_) {
      my $value = shift @_;
      $$driver->$driver_set($self, $id, $name, $value);
    } else {
      $$driver->$driver_get($self, $id, $name);
    }
  };
}

sub _build_hive_method {
  my ($self, $arg) = @_;

  my $id_method = $arg->{id_method};
  my $moniker   = ${ $arg->{moniker} };

  my $mutate_method = $self->method_name('mutate', $moniker);
  my $exists_method = $self->method_name('exists', $moniker);

  sub {
    my ($self) = @_;
    my $id = $self->$$id_method;
    # We should really get around to caching these in some awesome way.
    # -- rjbs, 2006-12-09
    Data::Hive->NEW({
      store_class => 'Param',
      store_args  => [ $self, {
        method => $mutate_method,
        exists => $exists_method,
      } ],
    });
  }
}

sub build_method {
  my ($self, $method, $arg) = @_;

  return $self->_build_mutate_method($arg) if $method eq 'mutate';
  return $self->_build_hive_method($arg) if $method eq 'hive';

  $method = 'delete_all' if $method eq 'empty';

  $self->SUPER::build_method($method, $arg);
}

sub driver_method_name {
  my ($self, $method) = @_;
  $self->SUPER::method_name($method, 'extra');
}

sub method_name {
  my ($self, $method, $moniker) = @_;

  return $moniker if $method eq 'hive';

  return "_$method\_$moniker";
}

=head1 AUTHOR

This code was written by Ricardo SIGNES.  His work in 2006 was sponsored by
Listbox.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, Ricardo SIGNES.  This code is free software, and is
available under the same terms as perl itself.

=head1 TODO

=over

=item * provide a customizable means to cache created Data::Hive objects

=back

=cut

1;
