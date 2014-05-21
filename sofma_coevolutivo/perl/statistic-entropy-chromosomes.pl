#!/usr/bin/perl

use strict;
use warnings;

use YAML qw(LoadFile Dump);
use Log::YAMLLogger;
use My::Couch;


# ENTROPY FUNCTIONS
sub entropy{
    my $p0 = shift;
    my $p1 = shift;
    
#    print "p0 = $p0\n";
#    print "p1 = $p1\n";
 
    my $H = 0;
    unless($p0 == 0){
        $H += $p0 * log($p0);
    }
    unless($p1 == 0){
        $H += $p1 * log($p1);
    }
    return -$H;
}

sub matrix_entropy{

    my $matrix = shift || die "Where are the chromosomes?";
    my $chrom_length = length(@{$matrix}[0]);
    my $chrom_ammount = scalar @{$matrix};
    my @entropies;
    for my $i (0..$chrom_length-1){
        my $total = 0;
        for my $chrom (@{$matrix}){
            my $bit = substr($chrom, $i, 1);
            $total += $bit;
        }
#        print "total 1s in the ${i}th row: $total out of $chrom_ammount\n";
        my $entropy = entropy(1 - ($total/$chrom_ammount), $total/$chrom_ammount);
        push @entropies, $entropy;
#        print "entropy: $entropy...";
#        <STDIN>;
    }
    my $sum = 0;
    map{ $sum += $_ } @entropies;
    my $mean = $sum / (scalar @entropies);
    if((scalar @entropies) != $chrom_length){
        print "ammount of bits: " . $chrom_length . "\n";
        print "ammount of entropies: " . (scalar @entropies) . "\n";
        die "not possible!";
    }
    
    return $mean;

}

# PARAMS
my $cdb_conf_file = shift || 'conf';
my $c = new My::Couch( "$cdb_conf_file.yaml" ) || die "Can't load: $@\n";
my $db = $c->db;

my $sofea_conf_file = shift || 'base';
my $sofea_conf = LoadFile("$sofea_conf_file.yaml") || die "Can't load $sofea_conf_file: $!\n";
$sofea_conf ->{'id'} = "log-entropy-chroms-".$sofea_conf ->{'id'};
my $logger = new Log::YAMLLogger $sofea_conf;

my $design_doc_name = "_design/by_gen";
my $filter = "chroms";
my $design_doc = $db->newDesignDoc($design_doc_name)->retrieve;
my $by_fitness = $design_doc->queryView($filter, descending => "true");
my $n_elements = @{$by_fitness->{'rows'}}[0]->{'value'}{'gen'};

# INITIALIZE ARRAY
my @chroms_by_gen;
for (1..$n_elements){
    my @empty_array;
    push @chroms_by_gen, \@empty_array;
}

# FILL ARRAY
for my $chrom (@{$by_fitness->{'rows'}}) {
    my $gen = int($chrom->{'value'}{'gen'});
    my $str = $chrom->{'value'}{'str'};
#    printf("gen = %i - str = %s\n", $gen, $str);
    my $chroms = $chroms_by_gen[$gen];
    push @{$chroms}, $str;
    $chroms_by_gen[$gen] = $chroms;
}


# CALCULATE ENTROPIES
my @entropies;
for (0..$n_elements){
    my $array = $chroms_by_gen[$_];
#    print $_ . ": \n";
#    for my $chrom (@{$array}){
#        print " - " . $chrom . "\n";
#    }
    my $entropy = matrix_entropy($array);
    push @entropies, $entropy;
#    print "entropy: $entropy\n";    
#    print "stopped... press ENTER to continue";
#    <STDIN>;
}

# PRINT ENTROPIES
my $entropies_to_string = "";
for (@entropies){
    $entropies_to_string .= " $_"
}
$logger->log( { Generations => (scalar @entropies),
                Entropies => $entropies_to_string });
    
$logger->close;

