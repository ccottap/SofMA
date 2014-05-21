#!/usr/bin/perl

use strict;
use warnings;

use Switch;

use YAML qw(LoadFile Dump); 
use Log::YAMLLogger;
use My::Couch;
use Manolo::Memetic qw(fitness_function apply_rule print_chromosome learn countsat);
use Time::HiRes qw(gettimeofday);
use List::Util qw(shuffle);


my $time_count_start = gettimeofday; #start


# LOG, CONF

my $cdb_conf_file = shift || 'conf';
my $c = new My::Couch( "$cdb_conf_file.yaml" ) || die "Can't load: $@\n";
my $db = $c->db;

my $sofea_conf_file = shift || 'base';
my $number = shift || '';
#print "number: $number\n";
my $sofea_conf = LoadFile("$sofea_conf_file.yaml") || die "Can't load $sofea_conf_file: $!\n";
$sofea_conf ->{'id'} = "log-eval-" . $sofea_conf->{'id'} . "-" . $number;
if ($sofea_conf->{'initial_delay'}) {
    sleep  $sofea_conf->{'initial_delay'};
    print "Delayed $sofea_conf->{'initial_delay'}\n";
}

my $logger = new Log::YAMLLogger $sofea_conf;


#PARAMS

my $number_of_subchromosomes = $sofea_conf->{'number_of_subchromosomes'}; 
my $subchromosome_length = $sofea_conf->{'subchromosome_length'}; 

my $fitness_function = $sofea_conf->{'fitness_function'};

my $max_fitness;
switch ($fitness_function) {

	case "trap"		{   $max_fitness = $subchromosome_length * $number_of_subchromosomes;   }
	
	case "mmdp"     { 
	                    if ($subchromosome_length != 6){
    	                    die "If the fitness function is 'mmdp' subchromosome_length must be 6! (it is actually $subchromosome_length)";
	                    }
	                    $max_fitness = $number_of_subchromosomes;
                    }
                    
	case "countsat"	{ 
	                    if ($number_of_subchromosomes != 1){
    	                    die "If the fitness function is 'countsat' number_of_subchromosomes must be 1! (it is actually $number_of_subchromosomes)";
	                    }
	                    $max_fitness = countsat($subchromosome_length, $subchromosome_length);
                    }
                    
	else { die "'$fitness_function' is not a valid function to evaluate? (trap, mmdp, countsat)" }
}

#DEBUG_MANOLOprint "fitness_function: $fitness_function\n";
#DEBUG_MANOLOprint "number_of_subchromosomes: $number_of_subchromosomes\n";
#DEBUG_MANOLOprint "subchromosome_length: $subchromosome_length\n";
#DEBUG_MANOLOprint "max_fitness: $max_fitness\n";


my $rule_population_size = $sofea_conf->{'learn_ammount_of_rules'};
my $chromosomes_per_rule = $sofea_conf->{'learn_chromosomes_per_rule'};
my $chrom_population_size = $rule_population_size * $chromosomes_per_rule;

my $max_evaluations = $sofea_conf->{'max_evaluations'};
my $max_seconds = $sofea_conf->{'max_seconds'};

my $learn_prob = eval($sofea_conf->{'learn_prob'});
my $learn_max_iter =$sofea_conf->{'learn_max_iter'};
my $learn_max_neighbour =$sofea_conf->{'learn_max_neighbour'};
#DEBUG_MANOLOprint "We'll make learn a " . $learn_prob*100 . "% of the population (max_iter = $learn_max_iter, max_neighbours = $learn_max_neighbour)\n";


# DESIGN DOCS

my $chrom_design_doc_name = $sofea_conf->{'learn_chrom_design_doc'};
my $chrom_filter = $sofea_conf->{'learn_chrom_filter'};
#DEBUG_MANOLOprint "learn chroms design doc = $chrom_design_doc_name\n";
#DEBUG_MANOLOprint "learn chroms filter = $chrom_filter\n";
my $chrom_design_doc = $db->newDesignDoc($chrom_design_doc_name)->retrieve;

my $rule_design_doc_name = $sofea_conf->{'learn_rule_design_doc'};
my $rule_filter = $sofea_conf->{'learn_rule_filter'};
#DEBUG_MANOLOprint "learn rules design doc = $rule_design_doc_name\n";
#DEBUG_MANOLOprint "learn rules filter = $rule_filter\n";
my $rule_design_doc = $db->newDesignDoc($rule_design_doc_name)->retrieve;


# my counters
my $total_indiv_learn = 0;
my $total_indiv_eval = 0;
my $total_indiv_treated = 0;
my $not_positive_learn = 0;

my $time_count_diff;

# solution doc, etc..
my $best_so_far = { data => { fitness => 0 }}; # Dummy for comparisons
my $best_rule_so_far = {};
my $solution_doc = $db->newDoc('solution');  
my $solution_found;
eval {
    $solution_found = $solution_doc->retrieve;
};

my $iteration = 0;

# MAIN LOOP
while (!$solution_found->{'data'}->{'found'}
     && !$solution_found->{'data'}->{'not_found'}) {
     
     # END OF ALGORITHM: max time {
     if($max_seconds > 0){
        my $time_count_now = gettimeofday; #now
        $time_count_diff = $time_count_now - $time_count_start;
        if ($time_count_diff > $max_seconds){
            printf("\n\nMaximum execution time (%.3f s) reached: (now: %.3f s)\n\n",
                       $max_seconds, $time_count_diff);
            $solution_found = $solution_doc->retrieve;
            my $max_time = { code => -2, message => "Maximum execution time ($max_seconds s.) reached"};
            $solution_found->{'data'}->{'not_found'} = $max_time;
            eval {
                $solution_found->update;
            };
            last; #don't work more
        }
    }
    #}

     
    # GET CHROMOSOMES {
    
    my $rand = rand();
    my $chrom_view = $chrom_design_doc->queryView($chrom_filter,
                                        startkey => $rand, limit=> $chrom_population_size);

    my @chromosomes = @{$chrom_view->{'rows'}};    

    # LESS THAN REQUIRED => GET MORE FROM THE BEGINNING (startkey = 0)
    my $got = scalar @chromosomes;
    if($got < $chrom_population_size){
#        print "CHEEEEEE!\n";
#        <STDIN>;
        $chrom_view = $chrom_design_doc->queryView($chrom_filter,
                                        startkey => 0, limit=> ($chrom_population_size - $got));
        push @chromosomes, @{$chrom_view->{'rows'}};
    }
     #}
     
     # GET RULES{

    my $rule_view = $rule_design_doc->queryView($rule_filter,
                                    startkey => rand(), limit=> $rule_population_size);
    my @rules = @{$rule_view->{'rows'}};
    
    # LESS THAN REQUIRED => GET MORE FROM THE BEGINNING (startkey = 0)
    $got = scalar @rules;
    if($got < $rule_population_size){
#        print "CHEEEEEE!\n";
#        <STDIN>;
        $rule_view = $rule_design_doc->queryView($rule_filter,
                                        startkey => 0, limit=> ($rule_population_size - $got));
        push @rules, @{$rule_view->{'rows'}};
    }
     #}
     
     # DEBUG {
#    print "got " . scalar @chromosomes . " chromosomes and " . scalar  @rules . " rules\n";
#    map { print "\t\t'" . $_->{'value'}{'str'} . "' (" . $_->{'value'}{'rnd'} .")\n" } @chromosomes;
#    print "---";
#    map { print "\t\t'" . $_->{'value'}{'ant'} . "' --> '" . $_->{'value'}{'con'} . "\n" } @rules;
    # } DEBUG
    
    if ((scalar @chromosomes == $chrom_population_size) && (scalar @rules == $rule_population_size)) {
    
        my $learned = 0;
        my @updated_chromosomes;
        my @updated_rules;
        
        my @chromosomes_shuffled = shuffle(@chromosomes);
        
        RULES: for my $rule (@rules){
        
            my $rule_learn;
        	my $rule_length = $rule->{'value'}{'len'} || die "rule '" . $rule->{'value'}{'ant'} . "' --> '" . $rule->{'value'}{'con'} . "' has no length attribute";
	        $$rule_learn{'ant'} = substr($rule->{'value'}{'ant'}, 0, $rule_length);
	        $$rule_learn{'con'} = substr($rule->{'value'}{'con'}, 0, $rule_length);
	        $$rule_learn{'len'} = $rule->{'value'}{'len'};
        
            my @fitness_improvements;
            
            for (1 .. $chromosomes_per_rule){
            
                # take a random chromosome
                my $chromosome = shift @chromosomes_shuffled;
                
                # DEBUG {
#                print_chromosome($chromosome->{'value'}{'str'}, "    chromosome", $subchromosome_length); print "\n";
#                (my $fitness, my @subfitnesses) = fitness_function($chromosome->{'value'}{'str'}, $fitness_function, $subchromosome_length);
#                print "                [";
#                map { print "  " . $_ . "  "} @subfitnesses;
#                print " ] = " . $fitness . "\n";
                # } DEBUG
                
                if(rand() <= $learn_prob){ # LEARNING PHASE
                
                    (my $new_chromosome, my $new_fitness, my $subevaluations, my $improvement)
                        = learn($chromosome->{'value'}{'str'}, $subchromosome_length,
                                     $rule_learn, $learn_max_iter, $learn_max_neighbour, $fitness_function);
                    
                    # DEBUG {
#    				print_chromosome($new_chromosome, "new chromosome", $subchromosome_length); print "\n";
#    				($new_fitness, my @new_subfitnesses) = fitness_function($new_chromosome, $fitness_function, $subchromosome_length);
#    			    print "                [";
#    			    map { print "  " . $_ . "  "} @new_subfitnesses;
#    			    print " ] = " . $new_fitness . "\n";
		            # } DEBUG
		            
                    # COUNTERS {
                    if($improvement == 0){
                        $not_positive_learn++;
                    }
                    $learned++;
                    $total_indiv_learn++;
                    # } COUNTERS

                    # SET CHROMOSOME
                    $chromosome->{'value'}{'str'} = $new_chromosome;
                    $chromosome->{'value'}{'fitness'} = $new_fitness;

                    push @fitness_improvements, $improvement;
                    
                    # DEBUG {
#                    print "improvement: $improvement --> [";
#    			    map { print "  " . $_ } @fitness_improvements; print " ]\n";
    			    # } DEBUG
    			    
                    $total_indiv_eval += ($subevaluations/$number_of_subchromosomes);
                }
                
                else{ # NORMAL EVALUATION
                
                    (my $fitness, my @subfitnesses) = fitness_function($chromosome->{'value'}{'str'}, $fitness_function, $subchromosome_length);
                    $chromosome->{'value'}{'fitness'} = $fitness;
                    
#                    print "DIDN'T LEARNED\n";
                    $total_indiv_eval++;
                }
                $total_indiv_treated++;
                
                # NEW CHROMOSOME
                my $new_guy = $db->newDoc( $chromosome->{'value'}{'_id'},
                                                                        $chromosome->{'value'}{'_rev'}, 
                                                                        $chromosome->{'value'} );
                # DEBUG {
#		        print "new guy:\n";
#		        print "\t * id: " . $new_guy->{'id'} . "\n";
#		        print "\t * rev: " . $new_guy->{'rev'} . "\n";
#		        print "\t * data: \n";
#		        foreach my $key (keys %{$new_guy->{'data'}}){
#		            print "\t\t - " . $key . ": " . $new_guy->{'data'}{$key} . "\n";
#		        }
                # } DEBUG
                
                push @updated_chromosomes, $new_guy;

                # replace if necessary {
                if ( $new_guy->{'data'}{'fitness'} > $best_so_far->{'data'}{'fitness'} ) {
                    $best_so_far = $new_guy;
                    $best_rule_so_far = $rule->{'value'};
                    #MANOLO
#DEBUG_MANOLO                    print "                                               ";
#DEBUG_MANOLO                    print_chromosome($best_so_far->{'data'}{'str'}, "best", $subchromosome_length);
#DEBUG_MANOLO                    printf(" (%f)", $best_so_far->{'data'}{'fitness'});
#DEBUG_MANOLO                    print " [" . substr($rule->{'value'}{'ant'}, 0, $rule->{'value'}{'len'}) . " --> ";
#DEBUG_MANOLO                    print substr($rule->{'value'}{'con'}, 0, $rule->{'value'}{'len'}) . " (" . $rule->{'value'}{'len'} . ")]\n\n";
                    #MANOLO
		        }
		        #}
		
		        # END OF ALGORITHM: solution found {
		        if ( $new_guy->{'data'}{'fitness'}  >= $max_fitness  ) {
			        print "\n\nSolution found \n\n"; # make algorithm stop
			        $solution_found = $solution_doc->retrieve;
			        $solution_found->{'data'}->{'found'} = $new_guy->{'data'};
			        eval {
				        $solution_found->update;
			        };
		            last RULES; # stop evaluating people
		        }
		        #}
		
		        # END OF ALGORITHM: max time {
		        if($max_seconds > 0){
	                my $time_count_now = gettimeofday; #now
                    $time_count_diff = $time_count_now - $time_count_start;
                    if ($time_count_diff >= $max_seconds){
                        printf("\n\nMaximum execution time (%.3f s) reached: (now: %.3f s)\n\n",
                                    $max_seconds, $time_count_diff);
		                $solution_found = $solution_doc->retrieve;
		                my $max_time = { code => -2, message => "Maximum execution time reached"};
		                $solution_found->{'data'}->{'not_found'} = $max_time;
		                eval {
			                $solution_found->update;
		                };
		                last RULES; # stop evaluating people
                    }
                }
                #}
                
                # END OF ALGORITHM: max evals {
                if(($max_evaluations > 0) && ($total_indiv_eval >= $max_evaluations)){
                    print "\n\nMaximum evaluations ($max_evaluations) reached\n\n";
                    $solution_found = $solution_doc->retrieve;
                    my $max_evals = { code => -1, message => "Maximum evaluations reached"};
                    $solution_found->{'data'}->{'not_found'} = $max_evals;
                    eval {
	                    $solution_found->update;
                    };
                    last RULES; # stop evaluating people
                }
                #}
                
                # DEBUG {
#                print "\n--------\n\n";
                # } DEBUG
                
            }
            
            # DEBUG {
#            print "improvements --> [";
#		    map { print "  " . $_ } @fitness_improvements; print " ]\n";
		    # } DEBUG
		    
		    $rule->{'value'}{'fitness'} = 0;
            unless (scalar @fitness_improvements == 0){
                my $sum = 0;
                map { $sum += $_ } @fitness_improvements;
                my $mean = $sum/(scalar @fitness_improvements);
#                printf("mean = %f\n", $mean);
#                print "mean = " . $mean . "\n";
                $rule->{'value'}{'fitness'} = $mean;
            }
            
            $rule->{'value'}{'era'} = $iteration;
            
            my $new_rule = $db->newDoc( $rule->{'value'}{'_id'},
                                        $rule->{'value'}{'_rev'}, 
                                        $rule->{'value'} );

            # DEBUG >
#	        print "new rule:\n";
#	        print "\t * id: " . $new_rule->{'id'} . "\n";
#	        print "\t * rev: " . $new_rule->{'rev'} . "\n";
#	        print "\t * data: \n";
#	        foreach my $key (keys %{$new_rule->{'data'}}){
#	            print "\t\t - " . $key . ": " . $new_rule->{'data'}{$key} . "\n";
#	        }
#            print "\n\n+++++++++\n\n";
            # < DEBUG
            
            push @updated_rules, $new_rule;
            
            # DEBUG >
#            foreach my $rule (@updated_rules){
#                print "new rule:\n";
#	            print "\t * id: " . $rule->{'id'} . "\n";
#	            print "\t * rev: " . $rule->{'rev'} . "\n";
#	            print "\t * data: \n";
#	            foreach my $key (keys %{$rule->{'data'}}){
#	                print "\t\t - " . $key . ": " . $rule->{'data'}{$key} . "\n";
#	            }
#                print "\n\n--------------------\n";
#            }
            # < DEBUG

        }

        # UPDATE {
        
	    my $response = $db->bulkStore(\@updated_chromosomes);
        my $conflicts = 0; 
        map( (defined $_->{'error'})?$conflicts++:undef, @$response );
        $logger->log( { Evaluated  => scalar(@$response),
                                    Best =>  $best_so_far->{'id'},
                                    Fitness => $best_so_far->{'data'}{'fitness'},
                                    Conflicts => $conflicts,
                                    Rand => $rand} );

        #MANOLO            
#DEBUG_MANOLO        print "                                              " . scalar @$response . " chromosomes educated [$learned educated]";
#        print " (" . (scalar @$response - $conflicts) . " actually, $conflicts conflicts)";
#DEBUG_MANOLO        print "\n";
        #MANOLO
        
        $response = $db->bulkStore(\@updated_rules);
        $conflicts = 0; 
        map( (defined $_->{'error'})?$conflicts++:undef, @$response );

        #MANOLO            
#DEBUG_MANOLO        print "                                              " . scalar @$response . " rules were updated";
#        print " (" . (scalar @$response - $conflicts) . " actually, $conflicts conflicts)";
#DEBUG_MANOLO        print "\n";
        #MANOLO
        
        # } UPDATE
    
    }
	else  {
        $logger->log( "Sleep 1" );
#        print "got " . scalar @chromosomes . " chromosomes and " . scalar  @rules . " rules\n";
#        print "not enough to evaluate/educate... sleeping\n";
        sleep 1;
    }

    #MANOLO
#    print "stopped... press ENTER to continue";
#    <STDIN>;
    #MANOLO
    
    eval {
        $solution_found = $solution_doc->retrieve;
    };

    $iteration++;

}

my $time_count_now = gettimeofday; #now
$time_count_diff = $time_count_now - $time_count_start;

my $percentage = 0;
unless ($total_indiv_treated == 0){
    $percentage = ($total_indiv_learn/$total_indiv_treated) * 100;
}

#DEBUG_MANOLOprint "Total treated: $total_indiv_treated\n";
#DEBUG_MANOLOprint "Learned: $total_indiv_learn\n";
#DEBUG_MANOLOprintf("%d out of %d individuals learned (%.3f %%)\n", $total_indiv_learn, $total_indiv_treated, $percentage);
#DEBUG_MANOLOprintf("Number of not positive learning: %d\n", $not_positive_learn);
#DEBUG_MANOLOprint "Total evaluations: $total_indiv_eval\n";
#DEBUG_MANOLOprint "Total time: $time_count_diff s.\n\n";

my $eval_doc = new CouchDB::Client::Doc ( { db => $db,
					   id => 'evaluations' } )->retrieve;
$eval_doc->{'data'}->{'evals'}  = $total_indiv_eval;
eval {
	$solution_found->update;
};

$logger->log( { TotalEvaluations => $total_indiv_eval,
                Learned =>  $total_indiv_learn,
                NotPositiveLearning => $not_positive_learn,
                Time => $time_count_diff,
                BestFitness =>  $best_so_far->{'data'}{'fitness'} });
$logger->close;

