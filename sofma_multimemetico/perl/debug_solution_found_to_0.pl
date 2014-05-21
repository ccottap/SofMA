#!/usr/bin/perl

use strict;
use warnings;

use My::Couch;

my $cdb_conf_file = shift || 'conf';
my $c = new My::Couch( "$cdb_conf_file.yaml" ) || die "Can't load: $@\n";
my $db = $c->db;

my $solution_doc = $db->newDoc('solution');
my $solution_found;
eval {
    $solution_found = $solution_doc->retrieve;
};
$solution_found->{'data'}->{'found'} = 0;
$solution_found->{'data'}->{'not_found'} = 0;

eval {
    $solution_found->update;
};
