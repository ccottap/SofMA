#!/usr/bin/perl

use strict;
use warnings;

use YAML qw(LoadFile Dump); 
use Log::YAMLLogger;
use Manolo::Memetic qw(produce_offspring_multimemetic);
use My::Couch;

#PARAMS
my $cdb_conf_file = shift || 'conf';
my $c = new My::Couch( "$cdb_conf_file.yaml" ) || die "Can't load: $@\n";
my $db = $c->db;

my $sofea_conf_file = shift || 'base';
my $sofea_conf = LoadFile("$sofea_conf_file.yaml") || die "Can't load $sofea_conf_file: $!\n";
$sofea_conf ->{'id'} = "log-repro-chrom-".$sofea_conf ->{'id'};

my $logger = new Log::YAMLLogger $sofea_conf;

my $population_size = $sofea_conf->{'repro_chrom_pop_size'};
my $substring_length = $sofea_conf->{'subchromosome_length'};
my $number_of_substrings = $sofea_conf->{'number_of_subchromosomes'};
my $chromosome_crossover_prob = eval($sofea_conf->{'chromosome_crossover_prob'});
my $chromosome_mutation_prob = eval($sofea_conf->{'chromosome_mutation_prob'});#DEBUG_MANOLO
#print "chromosome_crossover_prob = $chromosome_crossover_prob\n";#DEBUG_MANOLO
#print "chromosome_mutation_prob = $chromosome_mutation_prob\n";

my $rule_crossover_prob = eval($sofea_conf->{'rule_crossover_prob'});
my $rule_mutation_prob = eval($sofea_conf->{'rule_mutation_prob'});#DEBUG_MANOLO
#print "rule_crossover_prob = $rule_crossover_prob\n";#DEBUG_MANOLO
#print "rule_mutation_prob = $rule_mutation_prob\n";

my $max_rule_length = $sofea_conf->{'max_rule_length'};
my $min_rule_length = $sofea_conf->{'min_rule_length'};

# design docs
my $design_doc_name = $sofea_conf->{'repro_chrom_design_doc'} || die "repro_chrom_design_doc?";
my $filter = $sofea_conf->{'repro_chrom_filter'} || die "repro_chrom_filter?";
#print "repro chrom design doc = $design_doc_name\n";
#print "repro chrom filter = $filter\n";

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
#            print "str = " . $p->{'value'}{'str'} . " fitness = " . $p->{'value'}{'fitness'} . " rnd = " . $p->{'value'}{'rnd'} . "\n";
            push( @population, { str => $p->{'value'}{'str'}, rule => $p->{'value'}{'rule'} } );
        }
    
        # REPRODUCTION
    
#        print "population BEFORE: (" . @population .")\n";
#	    for(@population){
#		    print "str: '" . $$_{'str'} . "\n";
#		    print "rule: '" . $$_{'rule'}{'ant'} . " --> " . $$_{'rule'}{'con'} . " (len=" . $$_{'rule'}{'len'} . ")\n";
#	    }
#	    print "\n----------\n\n";

#    print "we got " . @population . " individuals from DB (we want " . $population_size . " new individuals)\n";
        my @new_population  = produce_offspring_multimemetic( \@population, $population_size, $substring_length, $number_of_substrings, $chromosome_crossover_prob, $chromosome_mutation_prob, $rule_crossover_prob, $rule_mutation_prob, $min_rule_length, $max_rule_length);

#    	print "population AFTER: (" . @new_population .")\n";
#    	for(@new_population){
#    		print "str: '" . $$_{'str'} . "\n";
#    		print "rule: '" . $$_{'rule'}{'ant'} . " --> " . $$_{'rule'}{'con'} . " (len=" . $$_{'rule'}{'len'} . ")\n";
#    	}
#    	print "\n----------\n\n";

        # REPRODUCTION
        
        my @new_docs;
        for (@new_population) {
            my $chrom_id = $$_{'str'} . " " . $$_{'rule'}{ant} . " --> " . $$_{'rule'}{con} . " (" . int($$_{'rule'}{len}) . ")";
#            print "doc id: " . $chrom_id . "\n";
            my $chrom_doc = {
          										str => $$_{'str'},
          										rule => $$_{'rule'},
          										rnd => rand(),
          										state => 0,
          										gen => $iteration,
          										type => 0
								        };
	        push @new_docs, $db->newDoc($chrom_id, undef, $chrom_doc);
        }

        $total_reproduced += @new_docs;

        my $response = $db->bulkStore( \@new_docs );
        my $conflicts = 0; 
        map( (defined $_->{'error'})?$conflicts++:undef, @$response );
        $logger->log( { conflicts => $conflicts,
		        population => scalar @population} );
            $total_conflicts += $conflicts;
            
        #MANOLO#DEBUG_MANOLO
#        print scalar @$response . " chromosomes created";
#        print " (" . (scalar @$response - $conflicts) . " actually, $conflicts conflicts)";#DEBUG_MANOLO
#        print "\n";
        #MANOLO
        
        $iteration++;

    }
    
    #MANOLO
#    print "stopped... press ENTER to continue";
#    <STDIN>;
    #MANOLO

    eval {
        $solution_found = $solution_doc->retrieve;
    };
    
}

#DEBUG_MANOLOprintf("%d chromosomes were created\n", $total_reproduced);

$logger->log( {Conflicts => $total_conflicts} );
$logger->close;

