#!/usr/bin/perl

use strict;
use warnings;

use YAML qw(LoadFile Dump); 
use Log::YAMLLogger;
use Manolo::Memetic qw(produce_rule_offspring);
use My::Couch;

#PARAMS
my $cdb_conf_file = shift || 'conf';
my $c = new My::Couch( "$cdb_conf_file.yaml" ) || die "Can't load: $@\n";
my $db = $c->db;

my $sofea_conf_file = shift || 'base';
my $sofea_conf = LoadFile("$sofea_conf_file.yaml") || die "Can't load $sofea_conf_file: $!\n";
$sofea_conf ->{'id'} = "log-repro-rules-".$sofea_conf ->{'id'};

my $logger = new Log::YAMLLogger $sofea_conf;

my $population_size = $sofea_conf->{'repro_rule_pop_size'};
my $rule_crossover_prob = eval($sofea_conf->{'rule_crossover_prob'});
my $rule_mutation_prob = eval($sofea_conf->{'rule_mutation_prob'});
#DEBUG_MANOLOprint "rule_crossover_prob = $rule_crossover_prob\n";
#DEBUG_MANOLOprint "rule_mutation_prob = $rule_mutation_prob\n";

my $max_rule_length = $sofea_conf->{'max_rule_length'};
my $min_rule_length = $sofea_conf->{'min_rule_length'};

# design docs
my $design_doc_name = $sofea_conf->{'repro_rule_design_doc'} || die "repro_rule_design_doc?";
my $filter = $sofea_conf->{'repro_rule_filter'} || die "repro_rule_filter?";
#DEBUG_MANOLOprint "repro rule design doc = $design_doc_name\n";
#DEBUG_MANOLOprint "repro rule filter = $filter\n";

my $design_doc = $db->newDesignDoc($design_doc_name)->retrieve;
my $sleep = shift || 1;
my $total_conflicts;

my $solution_doc = $db->newDoc('solution');  
my $solution_found;

my $total_reproduced = 0;

eval {
    $solution_found = $solution_doc->retrieve;
};

my $iteration = 1;

while (!$solution_found->{'data'}->{'found'}
     && !$solution_found->{'data'}->{'not_found'}) {
     
    my @query_results;
    my $view = $design_doc->queryView( $filter,
                                                                 startkey => rand(),
                                                                 limit => $population_size);
    @query_results = @{$view->{'rows'}};

    # LESS THAN REQUIRED => GET MORE FROM THE BEGINNING (startkey = 0) {
    my $got = scalar @query_results;
#    print "got " . scalar @query_results . "\n";
    if($got < $population_size){
        $view = $design_doc->queryView( $filter,
                                                                 startkey => 0,
                                                                 limit=> ($population_size - $got));
        push @query_results, @{$view->{'rows'}};
#        print "\t\tgot " . scalar @query_results . " now\n";
    }
    #}

    my @population;
    if ( !@query_results  )  {
        $logger->log( "Sleep $sleep" );
        sleep $sleep;
#        print "nothing to reproduce... sleeping\n";
    } else {

        for my $p (@query_results) {
#            print "rule: '" . $p->{'value'}{'ant'} . "' --> '" . $p->{'value'}{'con'} . "' (length = " . $p->{'value'}{'len'} . ")\n";
#            print " fitness = " . $p->{'value'}{'fitness'};
#            print " rnd = " . $p->{'value'}{'rnd'} . "\n";
            push( @population, { ant => $p->{'value'}{'ant'},
                                                  con => $p->{'value'}{'con'},
                                                  len => $p->{'value'}{'len'} });
        }
    
        # REPRODUCTION
    
#        print "\npopulation BEFORE: (" . @population .")\n";
#	    for(@population){
#		    print "'" . $$_{'ant'} . "' --> '" . $$_{'con'} . "' (length = " . $$_{'len'} . ")\n";
#	    }
#	    print "\n----------\n\n";
	    
        #    print "we got " . @population . " individuals from DB (we want " . $population_size . " new individuals)\n";
        my @new_population  = produce_rule_offspring( \@population, $population_size,
                $rule_crossover_prob, $rule_mutation_prob, $min_rule_length, $max_rule_length);

#	    print "population AFTER: (" . @new_population .")\n";
#	    for(@new_population){
#		    print "'" . $$_{'ant'} . "' --> '" .  $$_{'con'} . "' (length = " . $$_{'len'} . ")\n";
#	    }
#	    print "\n----------\n\n";

        #MANOLO
#        print "stopped... press ENTER to continue";
#        <STDIN>;
        #MANOLO

        # REPRODUCTION
        
        my @new_docs;
        for (@new_population) {
            my $rule_id = $$_{'ant'} . " --> " . $$_{'con'} . " (" . int($iteration) . ")";
#            print "doc id: " . $rule_id . "\n";
            my $rule_doc = {
          										ant => $$_{'ant'},
          										con => $$_{'con'},
          										len => $$_{'len'},
          										rnd => rand(),
          										state => 0,
          										type => 1,
          										gen => $iteration
								        };
	        push @new_docs, $db->newDoc($rule_id, undef, $rule_doc);
        }
        
        $total_reproduced += @new_docs;

        my $response = $db->bulkStore( \@new_docs );
        my $conflicts = 0; 
        map( (defined $_->{'error'})?$conflicts++:undef, @$response );
        $logger->log( { conflicts => $conflicts,
		        population => scalar @population} );
            $total_conflicts += $conflicts;
        
        #MANOLO
#DEBUG_MANOLO        print "                          " . scalar @$response . " rules created";
#        print " (" . (scalar @$response - $conflicts) . " actually, $conflicts conflicts)";
#DEBUG_MANOLO        print "\n";
        #MANOLO
            
        $iteration++;
        sleep 1;
    }

    #MANOLO
#    print "stopped... press ENTER to continue";
#    <STDIN>;
    #MANOLO

    eval {
        $solution_found = $solution_doc->retrieve;
    };
    
}

#DEBUG_MANOLOprintf("%d rules were created\n", $total_reproduced);

$logger->log( {Conflicts => $total_conflicts} );
$logger->close;

