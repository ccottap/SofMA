#!/usr/bin/perl

use strict;
use warnings;

use YAML qw(LoadFile Dump); 
use Log::YAMLLogger;
use My::Couch;

#PARAMS
my $cdb_conf_file = shift || 'conf';
my $c = new My::Couch( "$cdb_conf_file.yaml" ) || die "Can't load: $@\n";
my $db = $c->db;

my $sofea_conf_file = shift || 'base';
my $sofea_conf = LoadFile("$sofea_conf_file.yaml") || die "Can't load $sofea_conf_file: $!\n";
$sofea_conf ->{'id'} = "log-reaper-chrom-".$sofea_conf ->{'id'};

my $logger = new Log::YAMLLogger $sofea_conf;

my $population_size = $sofea_conf->{'base_chrom_pop_size'} || die "base_chrom_pop_size?";

my $design_doc_name = $sofea_conf->{'reaper_chrom_design_doc'} || die "reaper_chrom_design_doc?";
my $filter = $sofea_conf->{'reaper_chrom_filter'} || die "reaper_chrom_filter?";
#DEBUG_MANOLOprint "reaper chrom design doc = $design_doc_name\n";
#DEBUG_MANOLOprint "reaper chrom filter = $filter\n";
my $design_doc = $db->newDesignDoc($design_doc_name)->retrieve;

my $sleep = $sofea_conf->{'reaper_chrom_delay'} || 1;

my $solution_doc = $db->newDoc('solution');  
my $solution_found;

eval {
    $solution_found = $solution_doc->retrieve;
};

while (!$solution_found->{'data'}->{'found'}
     && !$solution_found->{'data'}->{'not_found'}) {

    my $by_fitness = $design_doc->queryView($filter);

    my @graveyard;
    my $all_of_them = scalar @{$by_fitness->{'rows'}} ;
    if ( $all_of_them <= $population_size ) {
        $logger->log( "Sleep $sleep" );
#        print "nothing to kill.. sleeping\n";
        sleep $sleep;
    } else {
        # $all_of_them - $population_size: we always keep a minimum ammount of individuals
        for ( my $r = 0; $r < $all_of_them - $population_size; $r++ ) {
            my $will_die = shift @{$by_fitness->{'rows'}};
#            print "str = " . $will_die->{'value'}{'str'} . " fitness = " . int($will_die->{'value'}{'fitness'}) . "\n";
            $will_die->{'value'}{'state'} = 1; # state == 1 --> dead
            push @graveyard, $db->newDoc( $will_die->{'id'}, $will_die->{'value'}{'_rev'}, $will_die->{'value'}) ; #deleted
        }
        my $response = $db->bulkStore( \@graveyard );
    
        #MANOLO
#DEBUG_MANOLO        print "                                                                                       " . @graveyard . " chromosomes died\n";
        #MANOLO
    
        $logger->log( { 
            Available => $all_of_them,
            Deleted => scalar(@$response) } );
    }
  
    #MANOLO
#    print "stopped... press ENTER to continue";
#    <STDIN>;
    #MANOLO

    eval {
        $solution_found = $solution_doc->retrieve;
    };
}

$logger->close;

