#!/usr/bin/perl

use strict;
use warnings;

use YAML qw(LoadFile Dump); 
#use Log::YAMLLogger;
use My::Couch;

# AS ALWAYS...
my $cdb_conf_file = shift || 'conf';
my $c = new My::Couch( "$cdb_conf_file.yaml" ) || die "Can't load: $@\n";
my $db = $c->db;

my $sofea_conf_file = shift || 'base';
my $sofea_conf = LoadFile("$sofea_conf_file.yaml") || die "Can't load $sofea_conf_file: $!\n";
$sofea_conf ->{'id'} = "reaper-".$sofea_conf ->{'id'};

#my $logger = new Log::YAMLLogger $sofea_conf;

my $population_size = 0;
# AS ALWAYS...
my $design_doc_name = "_design/chroms";
my $filter = "1-alive_without_fitness";
print "reaper design doc = $design_doc_name\n";
print "reaper filter = $filter\n";
my $design_doc = $db->newDesignDoc($design_doc_name)->retrieve;

my $sleep = $sofea_conf->{'reaper_delay'} || 1;

my $solution_doc = $db->newDoc('solution');  
my $solution_found;

eval {
    $solution_found = $solution_doc->retrieve;
};

while (!$solution_found->{'data'}->{'found'}
     && !$solution_found->{'data'}->{'not_found'}) {

    my $by_fitness = $design_doc->queryView($filter);

    my @population;
    my $all_of_them = scalar @{$by_fitness->{'rows'}} ;
    if ( $all_of_them == 0) {
        #    $logger->log( "Sleep $sleep" );
        sleep $sleep;
        #print "sleeping...\n";
    } else {
        for ( my $r = 0; $r < $all_of_them; $r++ ) {
            my $will_get_fitness = shift @{$by_fitness->{'rows'}};
            my $value = $will_get_fitness->{'value'};
            $$value{fitness} = int(rand(64)+1);
            push @population, $db->newDoc( $will_get_fitness->{'id'}, $will_get_fitness->{'value'}{'_rev'}, $value) ; #deleted
        }
        my $response = $db->bulkStore( \@population );
    
        #MANOLO
        print "                                                      " . @population . " got a random fitness\n";
        #MANOLO
    
        #    $logger->log( { 
        #		   Available => $all_of_them,
        #		   Deleted => scalar(@$response) } );
    }
  
    #MANOLO
    #print "stopped... press ENTER to continue";
    #<STDIN>;
    #MANOLO

    eval {
        $solution_found = $solution_doc->retrieve;
    };
}

#$logger->close;

