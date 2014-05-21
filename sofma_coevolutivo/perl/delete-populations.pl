#!/usr/bin/perl

use strict;
use warnings;

use My::Couch;

my $cdb_conf_file = shift || 'conf';
my $c = new My::Couch( "$cdb_conf_file.yaml" ) || die "Can't load: $@\n";
my $db = $c->db;

my $view = $db->listDocs();
my @all_docs;
for my $p ( @{$view} ) {
  if ( $p->{'id'} !~ /_design/ ) {
    push @all_docs, $p;
  }
}

#MANOLO
#print "ALL DOCS TO REMOVE:\n";
#print "\t", $_->{'id'}, "\n" for @all_docs;
#print "\n";
#MANOLO

my $response = $db->bulkDelete( \@all_docs );
sleep 1;
#DEBUG_MANOLOprint scalar @$response, " documents deleted\n";
