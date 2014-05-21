package Manolo::Memetic;

use warnings;
use strict;

use version;
our $VERSION = qv('10');

use base qw/Exporter/;
our @EXPORT = qw(random_flavored_chromosome random_chromosome random_rule trap mmdp countsat fitness_function partial_fitness_function apply_rule learn produce_offspring_multimemetic produce_chrom_offspring produce_rule_offspring crossover rule_crossover mutate mutate_rule print_chromosome);

use List::Util qw(shuffle);

use constant false => 0;
use constant true  => 1;


########## CREATION ##########

# random_flavored_chromosome(number_of_substrings, substrings_length)
sub random_flavored_chromosome {
	my $number_of_substrings = shift || die "how many substrings?";
	my $substrings_length = shift || die "length of the substrings?";
	my $flavor1 = shift;
	my $flavor2 = shift;
	#    print 'We\'re going to create ' . $number_of_substrings . ' substrings of ' . $substrings_length . " bits\n";
	my $string = '';
	my $length = $number_of_substrings * $substrings_length;
	for (1..$length) {
		$string .= (rand > 0.5) ? $flavor1 : $flavor2;
	}
	return $string;
}

# random_chromosome(number_of_substrings, substrings_length)
sub random_chromosome {
	my $number_of_substrings = shift || die "how many substrings?";
	my $substrings_length = shift || die "length of the substrings?";
	#    print 'We\'re going to create ' . $number_of_substrings . ' substrings of ' . $substrings_length . " bits\n";
	my $string = '';
	my $length = $number_of_substrings * $substrings_length;
	for (1..$length) {
		$string .= (rand > 0.5) ? 1 : 0;
	}
	return $string;
}

# random_rule_part(rule_length)
sub random_rule_part {
	my $rule_length = shift || die "rule length?";
#	print "We\'re going to create a part of a rule of length " . $rule_length . "\n";
	my $rule = "";
	for (1..$rule_length) {
		my $rand = rand;
		if($rand < 1/3){
			$rule .= '0';
		}
		elsif($rand > 2/3){
			$rule .= '1';
		}
		else{
			$rule .= '.';
		}
#		if($rand < 1/2){
#			$rule .= '0';
#		}
#		else{
#			$rule .= '1';
#		}
	}
	return $rule;
}

sub random_rule_antecedent{
	my $rule_length = shift || die "rule length?";
	return random_rule_part($rule_length);
}

sub random_rule_consequent{
	my $rule_length = shift || die "rule length?";
	return random_rule_part($rule_length);
}

sub random_rule{
	my $rule_length = shift || die "rule length?";
	return { ant => random_rule_antecedent($rule_length),
					con => random_rule_consequent($rule_length) }
}


########## FUNCTIONS ##########

# trap(count, substring_length)
sub trap {
	my $count = shift; # || die "count?";
	my $substring_length = shift || die "substring_length?";

    if ($count > $substring_length){
    	die "The number $count is greater than the substring length ($substring_length)";
	}
	
	if ($count == 0){
		return $substring_length;
	}
	else {
		return $count - 1; 
	}
}

our %mmdp_values = (
                    0 => 1,
                    1 => 0,
                    2 => 0.360384,
                    3 => 0.640576,
                    4 => 0.360384,
                    5 => 0,
                    6 => 1,
                );

# mmdp(count)
sub mmdp {
	my $count = shift;
    return $mmdp_values{$count};
}

sub binomial{
    my $n = shift;
    my $k = shift;
	my $r = 1;
	for (1 .. $k){
        $r *= $n + 1 - $_, $r /= $_;
    }
#    print "binomial($n, $k) = $r\n";
	return int($r);
}

# up to 512 bits still working with the binomial coefficient :D
# countsat(count, nbits)
sub countsat {
	my $x = shift;
	my $n = shift || die "how many bits has the chromosome?";
    return $x + $n*($n-1)*($n-2) - 2*($n-2)*binomial($x,2) + 6*binomial($x,3);
}


########## EVALUATION ##########

# ($count, @parcial_counts) fitness_function(string, function, substring_length?)
sub fitness_function {
	my $string = shift || die "where's the string to evaluate?";
	my $string_length = length($string);
	
	my $function =  shift || die "What's the function to evaluate? (trap, mmdp, countsat)";
#DEBUG_FITNESS_FUNCTION	print "FITNESS_FUNCTION: '$function'\n";
	my $trap = $function eq "trap";
    my $mmdp = $function eq "mmdp";
    my $countsat = $function eq "countsat";
    if (!($trap || $mmdp || $countsat)){
        die "Not valid function: '$function'";
    }
    
    my $substring_length;
	if($trap){
    	$substring_length = shift || die "which is the length of the substrings?";
	}
	elsif ($mmdp){
	    $substring_length = 6;
	}
	elsif ($countsat){
	    $substring_length = $string_length;
	}
	
	
#DEBUG_FITNESS_FUNCTION	print "string: " . $string . "\n";
	$string = reverse $string;
	my $total_count = 0;
	my $partial_count;
	my @partial_counts;
	my $partial_counts_length = 0;
	my $count = 0;
	my $i = 0;
	for (1..$string_length) {
		my $bit = chop($string);
#DEBUG_FITNESS_FUNCTION        print "BIT: $bit\n";
		$count += $bit;
		$i++;
		if ($i % $substring_length == 0){
		    
		    if($trap){
            	$partial_count = trap($count, $substring_length);
	        }
	        elsif ($mmdp){
	            $partial_count = mmdp($count);
	        }
	        elsif ($countsat){
	            $partial_count = countsat($count, $substring_length);
	        }
	        
#DEBUG_FITNESS_FUNCTION			print "PARTIAL COUNT: " . $partial_count . "\n";
			
			$partial_counts[$partial_counts_length] = $partial_count;
			$partial_counts_length++;
			
#DEBUG_FITNESS_FUNCTION			print "Parcial counts:";
#DEBUG_FITNESS_FUNCTION			map { print " '" . $_ . "'"} @partial_counts;
#DEBUG_FITNESS_FUNCTION			print "\n";
			
			$total_count += $partial_count;
#DEBUG_FITNESS_FUNCTION			print "TOTAL: " . $total_count . "\n";
			
			$count = 0;
		}
	}
	
#DEBUG_FITNESS_FUNCTION	print "TOTAL BITS: " . $i . "\n";
	my $total;
	map { $total += $_ } @partial_counts;
	if($total != $total_count){
		print "Total: " . $total . " != " . $total_count . " = Total count\n";
		print "Parcial counts:";
		map { print " '" . $_ . "'"} @partial_counts;
		print "\n";
		die;
	}
#DEBUG_FITNESS_FUNCTION	else{
#DEBUG_FITNESS_FUNCTION		print "Total: " . $total . " == " . $total_count . " = Total count\n";
#DEBUG_FITNESS_FUNCTION		print "Everything ok!\n";
#DEBUG_FITNESS_FUNCTION	}
	
	return ($total_count, @partial_counts);
}

# partial_count = partial_fitness_function(string, function, part?{trap,mmdp}, substring_length?{trap})
sub partial_fitness_function {
	my $string = shift || die "where's the string to evaluate?";
	my $string_length = length($string);
	
	my $function =  shift || die "What's the function to evaluate? (trap, mmdp, countsat)";
#DEBUG_PARTIAL_FITNESS_FUNCTION	print "PARTIAL_FITNESS_FUNCTION: '$function'\n";
	my $trap = $function eq "trap";
    my $mmdp = $function eq "mmdp";
    my $countsat = $function eq "countsat";
    if (!($trap || $mmdp || $countsat)){
        die "Not valid function: '$function'";
    }
    
    my $part;
    my $substring_length;
	if($trap){
	    $part = shift;
    	$substring_length = shift || die "which is the length of the substrings?";
	}
	elsif ($mmdp){
	    $part = shift;
	    $substring_length = 6;
	}
	elsif ($countsat){
	    $part = 0;
	    $substring_length = $string_length;
	}
	
	my $count = 0;
	my $substring;
	if ($countsat){
	    $substring = $string;
	}
	else{
    	$substring = substr($string, ($part * $substring_length), $substring_length);
	}
#DEBUG_PARTIAL_FITNESS_FUNCTION	print "String '" . $string . "'\n";
#DEBUG_PARTIAL_FITNESS_FUNCTION	print "Calculating partial fitness_function for part " . $part . ": '" . $substring . "'\n";
	my $i = 0;
	for (1..length($substring)) {
		my $bit = chop($substring);
#DEBUG_PARTIAL_FITNESS_FUNCTION       	print "BIT: $bit\n";
		$count += $bit;
		$i++;
	}
	
    my $partial_count;    
	if($trap){
	    $partial_count = trap($count, $substring_length);
    }
    elsif ($mmdp){
        $partial_count = mmdp($count);
    }
    elsif ($countsat){
        $partial_count = countsat($count, $substring_length);
    }
    
#DEBUG_PARTIAL_FITNESS_FUNCTION	print "PARCIAL fitness_function: " . $partial_count . "\n";
#DEBUG_PARTIAL_FITNESS_FUNCTION	print "\n";
	
	return $partial_count;
}

sub print_chromosome{
	my $string = shift || die "Where is the chromosome?";
	my $name = shift || die "Where is the name?";
	my $substring_length = shift || die "Where is the subchromosome length?";
	print $name . ": ";
	for (0 .. length($string)-1){
		print " " if($_ % $substring_length == 0);
		print substr($string, $_, 1);
	}
}

########## LEARNING ##########

# (string, fitness, subevaluations, improvement) = 
#     learn (string, substring_length, \%rule, maxiter, max_neighbours)
sub learn {
    my $current_chromosome = shift || die "where's the string to apply the rule to?";
    my $chromosome_length = length($current_chromosome);
	my $subchromosome_length = shift || die "where's the substring length?";
	my $rule = shift || die "where's the rule?";
	my $max_iter = shift || die "maximum number of iterations?";
	my $max_neighbours = shift || die "maximum number of neighbours to consider?";
	my $function =  shift || die "What's the function to evaluate? (trap, mmdp, countsat)";
	if($function eq "mmdp" && $subchromosome_length != 6){
	    die "If function is 'mmdp' subchromosome_length must be 6! (it is actually $subchromosome_length)";
	}
	
#PRINT DEBUG LEARN    print "\nOriginal chromosome: " . $current_chromosome . "\n";
#PRINT DEBUG LEARN	print "I will apply the rule of size $rule_length '" . $$rule{'ant'} . "' --> '" . $$rule{'con'} . "'\n";
#PRINT DEBUG LEARN    print "Subchromosomes have length = " . $subchromosome_length . "\n";
	
    (my $current_fitness, my @current_subfitnesses) = fitness_function($current_chromosome, $function, $subchromosome_length);
#PRINT DEBUG LEARN    print "the original fitness was " . $current_fitness . "\n";
    my $original_fitness = $current_fitness;
    
    my $subevaluations = @current_subfitnesses;
#PRINT DEBUG LEARN    print "subevaluations: $subevaluations\n";
    
    my $still_learning = true;
    my $iter = 0;
    while($still_learning && $iter < $max_iter){
			
#PRINT DEBUG LEARN			print "\n################ iteration $iter ################\n\n";
			my @perm = shuffle(0..$chromosome_length-1);
#PRINT DEBUG LEARN			print "perm: @perm (" . scalar @perm . ")\n\n";
            
            $still_learning = false;
            
            my $max_fitness = $current_fitness;
            my $max_chromosome = $current_chromosome;
            my @max_subfitnesses = @current_subfitnesses;
#PRINT DEBUG LEARN            print_chromosome($current_chromosome, "  current", $subchromosome_length);
#PRINT DEBUG LEARN            print " => " . $current_fitness . "\n";
#PRINT DEBUG LEARN            print "            "; map { print "  " . $_ . "  "} @current_subfitnesses; print "\n";
            
            if($max_neighbours >= scalar @perm){
                $max_neighbours = scalar @perm - 1;
            }
#PRINT DEBUG LEARN            print "\nnumber of neighbours to check: $max_neighbours\n";
			for (0..$max_neighbours){
			   
#PRINT DEBUG LEARN			    print "\n---------------- neighbour $_ ----------------\n\n";
			    # apply rule
			    (my $neighbour_chromosome, my @changes) = apply_rule($current_chromosome, $subchromosome_length, $rule, $perm[$_]);
			    
			    # re-evaluate
			    my @neighbour_subfitnesses = @current_subfitnesses;
				for my $part (@changes){
	                my $partial_fitness = partial_fitness_function($neighbour_chromosome, $function, $part, $subchromosome_length);
	                $neighbour_subfitnesses[$part] = $partial_fitness;
                }
                $subevaluations += @changes;
#PRINT DEBUG LEARN                print "subevaluations: $subevaluations\n";
                my $neighbour_fitness = 0;
                map { $neighbour_fitness += $_ } @neighbour_subfitnesses;
#PRINT DEBUG LEARN			    print_chromosome($neighbour_chromosome, "neighbour", $subchromosome_length);
#PRINT DEBUG LEARN			    print " => " . $neighbour_fitness . "\n";
#PRINT DEBUG LEARN			    print "            "; map { print "  " . $_ . "  "} @neighbour_subfitnesses;
#PRINT DEBUG LEARN			    print "{";
#PRINT DEBUG LEARN			    map { print $_ . " "} @changes;
#PRINT DEBUG LEARN			    print "}\n";
                
                # replace if necessary
				if($neighbour_fitness > $max_fitness){
#PRINT DEBUG LEARN                    print "REPLACE MAX WITH NEIGHBOUR! ($neighbour_fitness > $max_fitness)\n";
                    $max_chromosome = $neighbour_chromosome;
				    $max_fitness = $neighbour_fitness;
                    @max_subfitnesses = @neighbour_subfitnesses;
#PRINT DEBUG LEARN                    print_chromosome($max_chromosome, "      max", $subchromosome_length);
#PRINT DEBUG LEARN                    print " => " . $max_fitness . "\n";
#PRINT DEBUG LEARN                    print "            "; map { print "  " . $_ . "  "} @max_subfitnesses; print "\n";
                    $still_learning = true;
				}
			}
			
			if($still_learning){
                $current_chromosome = $max_chromosome;
			    $current_fitness = $max_fitness;
                @current_subfitnesses = @max_subfitnesses;
			}
#PRINT DEBUG LEARN			else{
#PRINT DEBUG LEARN			    print "NOTHING CHANGED... STOP LEARNING\n";
#PRINT DEBUG LEARN			}
			
			$iter++;
    }
    
#PRINT DEBUG LEARN    print "\n[$iter iterations]\n\n";
    
    my $fitness_improvement = $current_fitness - $original_fitness;
    return ($current_chromosome, $current_fitness, $subevaluations, $fitness_improvement);
    
}

# ($string, @changes) = apply_rule(string, substring_length, \%rule, position)
sub apply_rule {
	my $string = shift || die "where's the string to apply the rule to?";
	my $substring_length = shift || die "where's the substring length?";
	my $string_length = length($string);
	my $rule = shift || die "where's the rule?";
	my $antecedent = $$rule{'ant'};
	my $consequent = $$rule{'con'};
	my @consequent_chars = split("", $consequent);
	my $rule_length = length($antecedent);
	my $position = shift;
#	print "We'll start in " . $position . "\n";
	my @changes;
	my $changes_size = 0;
#    print "String            " . $string . "\n";
#    print "I will apply the rule of size " . $rule_length . ": " . $antecedent . " --> " . $consequent . "\n";
	my $i = 0;
		
	my $substring = substr ($string, $position, $rule_length);
#	print "Substring to check: '" . $substring . "'\n";

	# just in case we are at the end of the string
	my $current_length = length($substring);
	if($current_length < $rule_length){
		$substring .= substr ($string, 0, $rule_length - $current_length);
#		print "AAAAAHHHHH!!! We had to add at the end: '" . substr ($string, 0, $rule_length - $current_length) . "'\n";
#		print "Substring to check: '" . $substring . "'\n";
	}
	
	if($substring =~ m/^$antecedent$/){
#PRINT DEBUG LEARN			print "apply the rule from $position!\n";
		
		for (0..$rule_length-1){
		
			my $index = int((($position + $_ ) % $string_length)/$substring_length);
#PRINT DEBUG LEARN			print "" . (($position + $_ ) % $string_length) . "/" . $substring_length . " = " . $index . "\n";

#PRINT DEBUG LEARN			print "consequent[" . $_ . "] = '" . $consequent_chars[$_]  . "'\n";				
			if($consequent_chars[$_] ne '.'){
				
				
				# @changes
				my $index = int((($position + $_ ) % $string_length)/$substring_length);
#PRINT DEBUG LEARN				print "" . (($position + $_ ) % $string_length) . "/" . $substring_length . " = " . $index . "\n";
				if($changes_size == 0 || ($changes_size > 0 && $changes[$changes_size-1] != $index)){
					push @changes, $index;
					$changes_size++;
				}

                #	set it to 0 or 1
				substr ($string, ($position + $_ ) % $string_length, 1, $consequent_chars[$_]);
#				print "String now:        " . $string . "\n";
			}
		}
	}
#PRINT DEBUG LEARN	else{
#PRINT DEBUG LEARN		printf "do nothing\n";
#PRINT DEBUG LEARN    }

#	print "  -------------------------------------------------\n";
#	print "changes in parts: [";
#	map { print " " . $_ } @changes;
#	print " ]\n";
#	print "  -------------------------------------------------\n";
	return ($string, @changes);
}


########## REPRODUCTION ##########


# @new_chrom_population  = produce_offspring_multimemetic( \@population, $offspring_size, $subchromosome_length, $number_of_subchromosomes $chromosome_crossover_prob, $chromosome_mutation_prob, $rule_crossover_prob, $rule_mutation_prob, $max_rule_length, $min_rule_length);
sub produce_offspring_multimemetic {
	my $pool = shift || die "Pool missing";
	my $offspring_size = shift || die "Population size needed";
	my $substring_length = shift || die "substring length?";
	my $number_of_substrings = shift || die "number of substrings?";
	my $chromosome_crossover_prob = shift; # || die "Where's the chromosome crossover probability?";
	my $chromosome_mutation_prob = shift; # || die "Where's the chromosome mutation probability?";
	my $rule_crossover_prob = shift; # || die "Where's the rule crossover probability?";
	my $rule_mutation_prob = shift;# || die "Where's the rule mutation probability?";
	my $min_rule_length = shift || die "Where's the minimum rule length?";
	my $max_rule_length = shift || die "Where's the maximum rule length?";
	my @population = ();
	my $population_size = scalar( @$pool );
	for (1..$offspring_size/2)  {
		
		my $first = $pool->[rand($population_size)];
		my $second = $pool->[rand($population_size)];
		
#PRINT DEBUG REPRO_MULTIMEME		print "parent1: '" . $$first{'str'} . " '" . $$first{'rule'}{'ant'} . "' --> '" . $$first{'rule'}{'con'} . "' (" . $$first{'rule'}{'len'} . ")\n";
#PRINT DEBUG REPRO_MULTIMEME		print "parent2: '" . $$second{'str'} . " '" . $$second{'rule'}{'ant'} . "' --> '" . $$second{'rule'}{'con'} . "' (" . $$second{'rule'}{'len'} . ")\n";
		
		(my $child_string_1, my $child_string_2) = crossover($$first{'str'}, $$second{'str'}, $substring_length, $number_of_substrings, $chromosome_crossover_prob);
		(my $child_rule_1, my $child_rule_2) = rule_crossover($$first{'rule'}, $$second{'rule'}, $rule_crossover_prob);
		
		my $child1 = { str => mutate($child_string_1, $chromosome_mutation_prob), rule => mutate_rule($child_rule_1, $rule_mutation_prob, $min_rule_length, $max_rule_length)};
		my $child2 = { str => mutate($child_string_2, $chromosome_mutation_prob), rule => mutate_rule($child_rule_2, $rule_mutation_prob, $min_rule_length, $max_rule_length)};
		
		
#PRINT DEBUG REPRO_MULTIMEME        print "     got '" . $$child1{'str'} . " '" . $$child1{'rule'}{'ant'} . "' --> '" . $$child1{'rule'}{'con'} . "' (" . $$child1{'rule'}{'len'} . ")\n";
#PRINT DEBUG REPRO_MULTIMEME		print "     and '" . $$child2{'str'} . " '" . $$child2{'rule'}{'ant'} . "' --> '" . $$child2{'rule'}{'con'} . "' (" . $$child2{'rule'}{'len'} . ")\n";
		
		push @population, ($child1, $child2);
		
#PRINT DEBUG REPRO_MULTIMEME		print "population: (" . @population .")\n";
#PRINT DEBUG REPRO_MULTIMEME		for(@population){
#PRINT DEBUG REPRO_MULTIMEME			print "str: '" . $$_{'str'} . " '" . $$_{'rule'}{'ant'} . "' --> '" .  $$_{'rule'}{'con'} . "' (" . $$_{'rule'}{'len'} . ")\n";
#PRINT DEBUG REPRO_MULTIMEME		}
#PRINT DEBUG REPRO_MULTIMEME		print "--------------------------------\n";
		
	}
	
	return @population;
}

# @new_chrom_population  = produce_chrom_offspring( \@population, $offspring_size, $subchromosome_length, $number_of_subchromosomes, $chromosome_crossover_prob, $chromosome_mutation_prob);
sub produce_chrom_offspring {
	my $pool = shift || die "Pool missing";
	my $offspring_size = shift || die "Population size needed";
	my $substring_length = shift || die "substring length?";
	my $number_of_substrings = shift || die "number of substrings?";
	my $chromosome_crossover_prob = shift; # || die "Where's the chromosome crossover probability?";
	my $chromosome_mutation_prob = shift; # || die "Where's the chromosome mutation probability?";
	my @population = ();
	my $population_size = scalar( @$pool );
	for (1..$offspring_size/2)  {
		
		my $first = $pool->[rand($population_size)];
		my $second = $pool->[rand($population_size)];
		
#PRINT DEBUG REPRO		print "parent1: '" . $$first{'str'} . "\n";
#PRINT DEBUG REPRO		print "parent2: '" . $$second{'str'} . "\n";
		
		(my $child_string_1, my $child_string_2) = crossover($$first{'str'}, $$second{'str'}, $substring_length, $number_of_substrings, $chromosome_crossover_prob);
		
		my $child_1 = { str => mutate($child_string_1, $chromosome_mutation_prob)};
		my $child_2 = { str => mutate($child_string_2, $chromosome_mutation_prob)};
		
#PRINT DEBUG REPRO        print "     got '" . $$child_1{'str'} . "\n";
#PRINT DEBUG REPRO		print "     and '" . $$child_2{'str'} . "\n";
		
		push @population, ($child_1, $child_2);
		
#PRINT DEBUG REPRO		print "population: (" . @population .")\n";
#PRINT DEBUG REPRO		for(@population){
#PRINT DEBUG REPRO			print "str: '" . $$_{'str'} . "\n";
#PRINT DEBUG REPRO		}
#PRINT DEBUG REPRO		print "--------------------------------\n";
	}
	
	return @population;
}

sub mutate {
	my $chromosome = shift || die "Where's the chromosome?";
	my $prob = shift; # || die "Where's the mutation probability?";
#	print "Mutating chromosome: '" . $chromosome . "'\t";
	
	my $mutated = 0;
	for (0 .. length($chromosome)-1){
		if (rand() < $prob){
			substr($chromosome, $_, 1,
				( substr($chromosome, $_, 1) eq 1 ) ? 0 : 1 );
			$mutated++;
#			print "mutated in position " . $_ . "\n";
		}
	}
#	print $mutated . " bit(s) mutated\t";
#	print "return chromosome:   '" . $chromosome . "'\n";
	return $chromosome;
}

# @new_rule_population  = produce_rule_offspring( \@population, $offspring_size, $rule_crossover_prob, $rule_mutation_prob, $min_rule_length, $max_rule_length)
sub produce_rule_offspring {
	my $pool = shift || die "Pool missing";
	my $offspring_size = shift || die "Population size needed";
	my $rule_crossover_prob = shift; # || die "Where's the rule crossover probability?";
	my $rule_mutation_prob = shift;# || die "Where's the rule mutation probability?";
	my $min_rule_length = shift || die "Where's the minimum rule length?";
	my $max_rule_length = shift || die "Where's the maximum rule length?";
	my @population = ();
	my $population_size = scalar( @$pool );
	for (1..$offspring_size/2)  {
		
		my $first = $pool->[rand($population_size)];
		my $second = $pool->[rand($population_size)];
		
#PRINT DEBUG REPRRULE		print "parent1: '" . $$first{'ant'} . "' --> '" . $$first{'con'} . "' (" . $$first{'len'} . ")\n";
#PRINT DEBUG REPRRULE		print "parent2: '" . $$second{'ant'} . "' --> '" . $$second{'con'} . "' (" . $$second{'len'} . ")\n";
		
		(my $rule1, my $rule2) = rule_crossover($first, $second,$rule_crossover_prob);
		
#PRINT DEBUG REPRRULE		print "   cross '" . $$rule1{'ant'} . "' --> '" . $$rule1{'con'} . "' (" . $$rule1{'len'} . ")\n";
#PRINT DEBUG REPRRULE		print "     and '" . $$rule2{'ant'} . "' --> '" . $$rule2{'con'} . "' (" . $$rule2{'len'} . ")\n";
		
		my $child_1 = mutate_rule($rule1, $rule_mutation_prob, $min_rule_length, $max_rule_length);
		my $child_2 = mutate_rule($rule2, $rule_mutation_prob, $min_rule_length, $max_rule_length);
		
#PRINT DEBUG REPRRULE		print "     got '" . $$child_1{'ant'} . "' --> '" . $$child_1{'con'} . "' (" . $$child_1{'len'} . ")\n";
#PRINT DEBUG REPRRULE		print "     and '" . $$child_2{'ant'} . "' --> '" . $$child_2{'con'} . "' (" . $$child_2{'len'} . ")\n";
		
		push @population, ($child_1, $child_2);
		
#PRINT DEBUG REPRRULE		print "population: (" . @population .")\n";
#PRINT DEBUG REPRRULE		for(@population){
#PRINT DEBUG REPRRULE			print "'" . $$_{'ant'} . "' --> '" .  $$_{'con'} . "' (" . $$_{'len'} . ")\n";
#PRINT DEBUG REPRRULE		}
#PRINT DEBUG REPRRULE		print "--------------------------------\n";
	}
	
	return @population;
}

sub mutate_rule_part{
	my $part = shift;
	my $prob = shift; # || die "Where's the mutation probability?";
	my $mutated = 0;
	for (0 .. length($part)-1){
#		print "bit: '" . substr($part, $_, 1) . "'";
		if (rand() < $prob){
			my $mutation_bit = substr($part, $_, 1);
			my $new_bit;
			if($mutation_bit eq '.' ){
				$new_bit = ((rand > 0.5) ? "0" : "1");
			}
			elsif($mutation_bit == 1 ){
				$new_bit = ((rand > 0.5) ? "0" : ".");
			}
			else{
				$new_bit = ((rand > 0.5) ? "1" : ".");
			}
			substr($part, $_, 1, $new_bit);
			$mutated++;
#			print " --> '" . $new_bit . "' mutated";
		}
#		print "\n";
	}
#	print $mutated . " bit(s) mutated\t";
	return $part;
}

# length = mutate_length(length, min, max)
sub mutate_length {
    my $len = shift || die "Where's the length?";
    my $min = shift || die "Where's the minimum rule length?";
	my $max = shift || die "Where's the maximum rule length?";
	my $prob = shift;# || die "Where's the mutation probability?";
		
	if (rand() < $prob){
#PRINT DEBUG REPRRULE	    print "mutate!\n";
	    if($len == $min){
	        $len++;
	    }
	    elsif($len == $max){
	        $len--;
	    }
	    elsif (rand() < 0.5){
	        $len++;
	    }
	    else{
	        $len--;
	    }
	}
	
	return $len;
}
	

sub mutate_rule {
	my $rule = shift || die "Where's the rule?";
	my $prob = shift;# || die "Where's the mutation probability?";
	my $min = shift || die "Where's the minimum rule length?";
	my $max = shift || die "Where's the maximum rule length?";
	my $antecedent = $$rule{'ant'};
	my $consequent = $$rule{'con'};
	my $len = $$rule{'len'};
#	print "Mutating rule: '" . $antecedent . "' --> '" . $consequent . "'\t";

#	print "mutating antecedent...\n";
	$antecedent = mutate_rule_part($antecedent, $prob);
	
#	print "mutating consequent...\n";
	$consequent = mutate_rule_part($consequent, $prob);
	
#	print "mutating length...\n";
    if ($min != $max){
	    if($len < $min || $len > $max){
	        die $len . " is not a valid length for a rule (rule: '" . $antecedent . "' --> '" . $consequent . "')";
	    }
	    else{
    	    $len = mutate_length($len, $min, $max, $prob);
	    }
    }
    # else: rule is the same as max and min
	
#	print "\n";
	return { ant => $antecedent, con => $consequent, len => $len};
}


sub crossover {
	my $chromosome_1 = shift || die "chromosome 1?";
	my $chromosome_2 = shift || die "chromosome 2?";
    my $substring_length = shift || die "substring length?";
	my $number_of_substrings = shift || die "number of substrings?";
	my $chromosome_crossover_prob = shift; # || die "crossover probability?";
#	print "crossover - 1: " . $chromosome_1 ."\n";
#	print "crossover - 2: " . $chromosome_2 ."\n";
#	print "crossover prob: " . $chromosome_crossover_prob ."\n";
	
	if(rand() < $chromosome_crossover_prob){
	
        my $length = length($chromosome_1);
	    my $xover_point_1;
	    my $range;
	    
	    if ($number_of_substrings > 1){
	        $xover_point_1 = (int rand( $length/$substring_length ) ) * $substring_length;
	        $range = (int rand ( ($length - $xover_point_1)/$substring_length + 1) ) * $substring_length;
    #	    print "length = " . $length . "\n";
    #	    print "substring length = " . $substring_length . "\n";
#	        print "xover_point_1 = " .$xover_point_1 ."\n";
#	        print "range = " .$range . "\n";
        }
        elsif ($number_of_substrings == 1){
	        $xover_point_1 = int rand( $length - 2 );
            $range = 1 + int rand ( $length - $xover_point_1 );
    #	    print "length = " . $length . "\n";
    #	    print "substring length = " . $substring_length . "\n";
#	        print "xover_point_1 = " .$xover_point_1 ."\n";
#	        print "range = " .$range . "\n";
        }
        else{
            die "Invalid number of substrings! (" . $number_of_substrings . ")";
        }
	    my $swap_chrom = $chromosome_1;
	    substr($chromosome_1, $xover_point_1, $range,
		    substr($chromosome_2, $xover_point_1, $range) );
	    substr($chromosome_2, $xover_point_1, $range,
		    substr($swap_chrom, $xover_point_1, $range) );
		    
	}
#	else{
#	    print "No crossover\n";
#	}

#	print "child - 1: " . $chromosome_1 ."\n";
#	print "child - 2: " . $chromosome_2 ."\n";
#    print "-------------------\n";

	return ( $chromosome_1, $chromosome_2 );
}

# %rule = rule_crossover(%rule_1, %rule_2)
sub rule_crossover {
	my $rule_1 = shift || die "rule 1?";
	my $rule_2 = shift || die "rule 2?";
	my $rule_crossover_prob = shift; # || die "crossover probability?";
	if(rand() < $rule_crossover_prob){
		my $ant1 = $$rule_1{'ant'};
		$$rule_1{'ant'} = $$rule_2{'ant'};
		$$rule_2{'ant'} = $ant1;
		
		# length
		my $len1 = $$rule_1{'len'};
		if(rand() < 0.5){
		    $$rule_1{'len'} = $$rule_2{'len'};
		}
		if(rand() < 0.5){
		    $$rule_2{'len'} = $len1;
		}
		
	}
#	else{
#	    print "No crossover\n";
#	}
	
	return ( $rule_1, $rule_2 );
}

"Manolo"; # Magic true value required at end of module
__END__
