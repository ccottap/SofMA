#!/usr/bin/perl

use strict;
use warnings;

use YAML qw(LoadFile Dump);
use Log::YAMLLogger;
use My::Couch;

#ENTROPY FUNCTIONS

sub log10 {
    my $n = shift;
    return log($n)/log(10);
}

sub entropy{
    my $probabilities = shift || die "Where are the probabilities?";
    
#    print "probabilities:";
#    map { print " $_" } @{$probabilities};
#    print "\n";
 
    my $H = 0;
    
    for (@{$probabilities}){
        unless($_ == 0){
            $H += $_ * log($_);
        }
    }

    return -$H;
}

sub matrix_entropy{

    my $matrix = shift || die "Where are the chromosomes?";
    my $chrom_length = length(@{$matrix}[0]->{'str'});
    my $chrom_ammount = scalar @{$matrix};
    my @entropies;
    for my $i (0..$chrom_length-1){
        my $total0 = 0;
        my $total1 = 0;
        my $totalp = 0;
        for my $chrom (@{$matrix}){
            if($i < ($chrom->{'len'}*2)){
                my $bit = substr($chrom->{'str'}, $i, 1);
                if($bit eq '0'){
                    $total0++;
                }
                elsif($bit eq '1'){
                    $total1++;
                }
                elsif($bit eq '.'){
                    $totalp++;
                }
                else{
                    die "character $bit not valid!";
                }
#                print $bit;
            }
        }
#        print "\n";
#        print "total '0' in the ${i}th row: $total0 out of $chrom_ammount\n";
#        print "total '1' in the ${i}th row: $total1 out of $chrom_ammount\n";
#        print "total '.' in the ${i}th row: $totalp out of $chrom_ammount\n";
        my @probabilities;
        push @probabilities, $total0/$chrom_ammount;
        push @probabilities, $total1/$chrom_ammount;
        push @probabilities, $totalp/$chrom_ammount;
        my $entropy = entropy(\@probabilities);
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

sub length_entropy{

    my $matrix = shift || die "Where are the chromosomes?";
    my $min_rule_length = shift || "min_rule_length?";
    my $max_rule_length = shift || "max_rule_length?";
#    print "min_rule_length: $min_rule_length\n";
#    print "max_rule_length: $max_rule_length\n";

    my $chrom_ammount = scalar @{$matrix};
    my @probabilities = (0) x ($max_rule_length - $min_rule_length + 1);
    for my $chrom (@{$matrix}){
#        print "len: " . $chrom->{'len'} . "\n";
        $probabilities[$chrom->{'len'}-$min_rule_length]++;
    }
    map { $_ = $_/$chrom_ammount } @probabilities;
    my $entropy = entropy(\@probabilities);
#    print "entropy: $entropy...";
#    <STDIN>;
    
    return $entropy;

}

sub length_mean{

    my $matrix = shift || die "Where are the chromosomes?";

    my $chrom_ammount = scalar @{$matrix};
    my $sum = 0;
    for my $chrom (@{$matrix}){
        $sum += $chrom->{'len'};
#        print "len: " . $chrom->{'len'} . "\n";
    }
    
#    print "sum: $sum\n";
#    print "return: " . ($sum/$chrom_ammount) . "...";
#    <STDIN>;
    
    return $sum/$chrom_ammount;

}

# PARAMS
my $cdb_conf_file = shift || 'conf';
my $c = new My::Couch( "$cdb_conf_file.yaml" ) || die "Can't load: $@\n";
my $db = $c->db;

my $sofea_conf_file = shift || 'base';
my $sofea_conf = LoadFile("$sofea_conf_file.yaml") || die "Can't load $sofea_conf_file: $!\n";
$sofea_conf ->{'id'} = "log-entropy-rules-".$sofea_conf ->{'id'};
my $logger = new Log::YAMLLogger $sofea_conf;

my $max_rule_length = $sofea_conf->{'max_rule_length'};
my $min_rule_length = $sofea_conf->{'min_rule_length'};

my $design_doc_name = "_design/by_gen";
my $filter = "rules";
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
    my $str = $chrom->{'value'}{'ant'} . $chrom->{'value'}{'con'};
    my $len = $chrom->{'value'}{'len'};
#    printf("gen = %i - str = %s\n", $gen, $str);
    my $chroms = $chroms_by_gen[$gen];
    push @{$chroms}, { str => $str, len => $len};
    $chroms_by_gen[$gen] = $chroms;
}


# CALCULATE ENTROPIES
my @entropies;
my @length_entropies;
my @length_means;
for (0..$n_elements){
    my $array = $chroms_by_gen[$_];
#    print $_ . ": \n";
#    for my $chrom (@{$array}){
#        print " - " . $chrom . "\n";
#    }
    my $entropy = matrix_entropy($array);
    my $length_entropy = length_entropy($array, $min_rule_length, $max_rule_length);
    my $length_mean = length_mean($array);
    push @entropies, $entropy;
    push @length_entropies, $length_entropy;
    push @length_means, $length_mean;
#    print "entropy: $entropy\n";    
#    print "stopped... press ENTER to continue";
#    <STDIN>;
}

# PRINT ENTROPIES
my $entropies_to_string = "";
for (@entropies){
    $entropies_to_string .= " $_"
}
my $length_entropies_to_string = "";
for (@length_entropies){
    $length_entropies_to_string .= " $_"
}
my $length_means_to_string = "";
for (@length_means){
    $length_means_to_string .= " $_"
}
$logger->log( { Generations => (scalar @entropies),
                Entropies => $entropies_to_string,
                LengthEntr => $length_entropies_to_string,
                LengthMean => $length_means_to_string });
    
$logger->close;

