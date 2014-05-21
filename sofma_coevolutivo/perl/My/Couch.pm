package My::Couch;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.1');
use YAML qw(LoadFile ); 
use CouchDB::Client;

use base qw/Exporter/;

our @EXPORT = qw/int_rand/;

sub new {
  my $class = shift;
  my $conf_param = shift;
  my $conf;
  if ( $conf_param =~ /\.yaml$/ ) {
    $conf = LoadFile($conf_param) || carp "Can't load conf: $!\n";
  } else {
    $conf = $conf_param;
  }
  
  my $c = CouchDB::Client->new(uri => $conf->{'couchurl'}) ;
  $c->testConnection or carp "The server cannot be reached";
  my $db;
  eval {
    $db = $c->newDB($conf->{'couchdb'})->create;
  };
  if ( $@ ) {
    $db = $c->newDB($conf->{'couchdb'});
  }
  my $self = { _db => $db };
  bless $self, $class;
  return $self;
}

sub db {
   my $self = shift;
  return $self->{'_db'};
}

sub int_rand {
  my $constant = 10;
  my $range = shift;
  my $rnd = rand( $range );
  return int($rnd*$constant)/$constant;
}

"¿Cómo?"; # Magic true value required at end of module
__END__

=head1 NAME

My::Couch - Connect to CouchDB


=head1 VERSION

Basic functions for connecting to Couch


=head1 SYNOPSIS

    use My::Couch;

    my $cdb_conf_file = shift || 'conf';
    my $c = new My::Couch( "$cdb_conf_file.yaml" ) || die "Can't load: $@\n";
    my $db = $c->db;

=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
