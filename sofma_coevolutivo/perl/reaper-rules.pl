#!/usr/bin/perl

use strict;
use warnings;

use YAML qw(LoadFile Dump); 
use Log::YAMLLogger;
use My::Couch;
use Time::HiRes qw(gettimeofday);

#PARAMS
my $cdb_conf_file = shift || 'conf';
my $c = new My::Couch( "$cdb_conf_file.yaml" ) || die "Can't load: $@\n";
my $db = $c->db;

my $sofea_conf_file = shift || 'base';
my $sofea_conf = LoadFile("$sofea_conf_file.yaml") || die "Can't load $sofea_conf_file: $!\n";
$sofea_conf ->{'id'} = "log-reaper-rules-".$sofea_conf ->{'id'};

my $logger = new Log::YAMLLogger $sofea_conf;

my $population_size = $sofea_conf->{'base_rule_pop_size'} || die "base_rule_pop_size?";

my $design_doc_name = $sofea_conf->{'reaper_rule_design_doc'} || die "reaper_rule_design_doc?";
my $filter = $sofea_conf->{'reaper_rule_filter'} || die "reaper_rule_filter?";
#DEBUG_MANOLOprint "reaper rules design doc = $design_doc_name\n";
#DEBUG_MANOLOprint "reaper rules filter = $filter\n";
my $design_doc = $db->newDesignDoc($design_doc_name)->retrieve;

my $ageing_operator = eval($sofea_conf->{'ageing_operator'}) || die "ageing operator?";

my $sleep = $sofea_conf->{'reaper_rule_delay'} || 1;

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
#        print "nothing to kill... sleeping\n";
        sleep $sleep;
    } else {
    
        # ERA{
        my $era_design_doc_name = "_design/docs";
        my $era_filter = "era_docs";
        my $era_design_doc = $db->newDesignDoc($era_design_doc_name)->retrieve;
#        my $time_count_start = gettimeofday; #start
        my $era_view = $era_design_doc->queryView($era_filter,  descending => "true", limit=> 1);
        
#        my $time_count_end = gettimeofday; #end
#        my $time_count_total = $time_count_end - $time_count_start;
#        print "query lasted $time_count_total s.\n";
        
        my $era_doc = shift @{$era_view->{'rows'}};
        my $era = $era_doc->{'value'}{'era'};
#        print "era = $era\n (STOPPED)";
#        <STDIN>;
        #}
    
         my @result = @{$by_fitness->{'rows'}};
         
        # DEBUG {
#        print "got " . scalar @result . " rules\n";
#        map { printf("\t\t%.2f - '%s' --> '%s'\n", $_->{'value'}{'fitness'}, $_->{'value'}{'ant'}, $_->{'value'}{'con'}) } @result;
        # } DEBUG
    
        # ageing population
        foreach (@result){
            my $era_diff = $era - ($_->{'value'}{'era'});
#            print "era diff: $era_diff\n";
            my $coef = $ageing_operator**$era_diff;
#            print "coef: $coef\n";
#            printf("\t\t%f - '%s' --> '%s'\n", $_->{'value'}{'fitness'}, $_->{'value'}{'ant'}, $_->{'value'}{'con'});
            $_->{'value'}{'real_fitness'} = ($_->{'value'}{'fitness'}) * $coef;
#            print "real fitness = " . $_->{'value'}{'real_fitness'} . "\n------------\n";
        }
        
        # ordering population
        @result = sort { $a->{'value'}{'real_fitness'} <=> $b->{'value'}{'real_fitness'} } @result;
        
        # DEBUG {
#        print "got " . scalar @result . " rules\n";
#        map { printf("\t\t%.2f (%.2f) - '%s' --> '%s'\n", $_->{'value'}{'fitness'}, $_->{'value'}{'real_fitness'}, $_->{'value'}{'ant'}, $_->{'value'}{'con'}) } @result;
        # } DEBUG
    
        # $all_of_them - $population_size: we always keep a minimum ammount of individuals
        for ( my $r = 0; $r < $all_of_them - $population_size; $r++ ) {
            my $will_die = shift @result;
            $will_die->{'value'}{'state'} = 1; # state == 1 --> dead
            push @graveyard, $db->newDoc( $will_die->{'id'}, $will_die->{'value'}{'_rev'}, $will_die->{'value'}) ; #deleted
        }
        
        my $response = $db->bulkStore( \@graveyard );
    
        #MANOLO
#DEBUG_MANOLO        print "                                                                                                               " . scalar @$response . " rules died\n";
        #MANOLO
    
        $logger->log( { 
            Available => $all_of_them,
            Deleted => scalar(@$response) } );
        
        # make the rest have a real_fitness
        for ( my $r = 0; $r < $population_size; $r++ ) {
            my $will_survive = shift @result;
            push @graveyard, $db->newDoc( $will_survive->{'id'}, $will_survive->{'value'}{'_rev'}, $will_survive->{'value'}) ; #deleted
        }
        
        $response = $db->bulkStore( \@graveyard );
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

