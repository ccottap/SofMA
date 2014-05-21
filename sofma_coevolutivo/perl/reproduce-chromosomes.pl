#!/usr/bin/perl

use strict;
use warnings;

use YAML qw(LoadFile Dump); 
use Log::YAMLLogger;
use Manolo::Memetic qw(produce_chrom_offspring);
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
my $chromosome_mutation_prob = eval($sofea_conf->{'chromosome_mutation_prob'});
#DEBUG_MANOLOprint "chromosome_crossover_prob = $chromosome_crossover_prob\n";
#DEBUG_MANOLOprint "chromosome_mutation_prob = $chromosome_mutation_prob\n";

# design docs
my $design_doc_name = $sofea_conf->{'repro_chrom_design_doc'} || die "repro_chrom_design_doc?";
my $filter = $sofea_conf->{'repro_chrom_filter'} || die "repro_chrom_filter?";

#DEBUG_MANOLOprint "repro chrom design doc = $design_doc_name\n";
#DEBUG_MANOLOprint "repro chrom filter = $filter\n";

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
            push( @population, { str => $p->{'value'}{'str'} } );
        }
    
        # REPRODUCTION
        
#    print "population BEFORE: (" . @population .")\n";
#	for(@population){
#		print "str: '" . $$_{'str'} . "\n";
#	}
#	print "\n----------\n\n";

#    print "we got " . @population . " individuals from DB (we want " . $population_size . " new individuals)\n";
        my @new_population  = produce_chrom_offspring( \@population, $population_size, $substring_length, $number_of_substrings, $chromosome_crossover_prob, $chromosome_mutation_prob);

#	print "population AFTER: (" . @new_population .")\n";
#	for(@new_population){
#		print "str: '" . $$_{'str'} . "\n";
#	}
#	print "\n----------\n\n";

        # REPRODUCTION
        
        my @new_docs;
        for (@new_population) {
            my $chrom_id = $$_{'str'} . " (" . int($iteration) . ")";
#            print "doc id: " . $chrom_id . "\n";
            my $chrom_doc = {
          										str => $$_{'str'},
          										rnd => rand(),
          										state => 0,
          										type => 0,
          										gen => $iteration
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
            
        #MANOLO
#DEBUG_MANOLO        print scalar @$response . " chromosomes created";
#        print " (" . (scalar @$response - $conflicts) . " actually, $conflicts conflicts)";
#DEBUG_MANOLO        print "\n";
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

