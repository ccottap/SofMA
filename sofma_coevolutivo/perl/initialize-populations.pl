#!/usr/bin/perl

use strict;
use warnings;

use YAML qw(LoadFile Dump); 
use CouchDB::Client;
use My::Couch;
use Manolo::Memetic qw(random_chromosome random_rule);


# PARAMS

my $cdb_conf_file = shift || 'conf';
my $c = new My::Couch( "$cdb_conf_file.yaml" ) || die "Can't load: $@\n";
my $db = $c->db;

my $sofea_conf_file = shift || 'base';
my $sofea_conf = LoadFile("$sofea_conf_file.yaml") || die "Can't load $sofea_conf_file: $!\n";

my $number_of_subchromosomes = $sofea_conf->{'number_of_subchromosomes'}; 
my $subchromosome_length = $sofea_conf->{'subchromosome_length'}; 
my $chrom_population_size = $sofea_conf->{'initial_chrom_pop_size'};

my $rule_population_size = $sofea_conf->{'initial_rule_pop_size'};
my $max_rule_length = $sofea_conf->{'max_rule_length'};
my $min_rule_length = $sofea_conf->{'min_rule_length'};

#CHROMOSOMES

my @population = map( random_chromosome($number_of_subchromosomes,
            $subchromosome_length), 1..$chrom_population_size );
		      
my @chrom_docs;
for (0..$chrom_population_size-1) {
    my $chrom_id = $population[$_] . " (0)";
	my $chrom_doc = {
  										str => $population[$_],
  										rnd => rand(),
  										state => 0, # state == 0 --> alive
  										type => 0, # type = 0 --> chromosome
  										gen => 0
								};
	push @chrom_docs, $db->newDoc($chrom_id, undef, $chrom_doc);
}

my $response = $db->bulkStore( \@chrom_docs );

my $conflicts = 0; 
map( (defined $_->{'error'})?$conflicts++:undef, @$response );
#DEBUG_MANOLOprint scalar @$response . " chromosomes created";
#print " (" . (scalar @$response - $conflicts) . " actually, $conflicts conflicts)";
#DEBUG_MANOLOprint "\n";


# RULES

my @rules = map( random_rule($max_rule_length), 1..$rule_population_size );

my @rule_docs;
for (0..$rule_population_size-1) {
    my $rule_id = ${$rules[$_]}{'ant'} . " --> " . ${$rules[$_]}{'con'} . " (0)";
    my $rule_length = int(rand($max_rule_length - $min_rule_length + 1) + $min_rule_length);
#    printf("initial rule length = %i (min=%i, max=%i)\n", $rule_length, $min_rule_length, $max_rule_length);
    my $rule_doc = {
  										ant => ${$rules[$_]}{'ant'},
  										con => ${$rules[$_]}{'con'},
  										len => $rule_length,
  										rnd => rand(),
  										state => 0, # state == 0 --> alive
  										type => 1, # type = 1 --> rule
  										gen => 0
								};
	push @rule_docs, $db->newDoc($rule_id, undef, $rule_doc);
}

$response = $db->bulkStore( \@rule_docs );

$conflicts = 0; 
map( (defined $_->{'error'})?$conflicts++:undef, @$response );
#DEBUG_MANOLOprint scalar @$response . " rules created";
#print " (" . (scalar @$response - $conflicts) . " actually, $conflicts conflicts)";
#DEBUG_MANOLOprint "\n";


# EVALUATION AND SOLUTION DOCUMENT
$response = $db->newDoc( 'evaluations', undef, { evals => 0} )->create;
#DEBUG_MANOLOprint "created \"evaluations\" document\n";
$response = $db->newDoc( 'solution', undef, { found => 0, not_found => 0} )->create;
#DEBUG_MANOLOprint "created \"solution\" document\n";

