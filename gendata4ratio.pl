=b
If the last element number could be 0, you need to check the output data files.
=cut

use strict;
use warnings;
use Cwd;
use POSIX;
use Algorithm::Combinatorics qw(variations_with_repetition);
use List::Util qw(sum);

my $currentPath = getcwd();

my @dlp_element = ("Sn", "Pb","Te");
my $subgrpNum = 2;### group number in your template structures

my @datafile = `find ./template_data -maxdepth 1 -name "*.data"`;
map { s/^\s+|\s+$//g; } @datafile;
die "No data files\n" unless(@datafile);

#house keeping
`rm -rf $currentPath/ele4ratio`;
`mkdir -p  $currentPath/ele4ratio`;
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

for my $f (@datafile){

my $temp_file = "$f";#you need to
$temp_file =~ m/.+-(\d+).data/;
die "No plane orientation information in $temp_file" unless($1); 
my $plane = "$1";
my @ele = `grep -v '^[[:space:]]*\$' $temp_file|grep -A 10000 Atoms |grep -v Atoms|grep -v -- '--'|awk '{print \$2}'`;
map { s/^\s+|\s+$//g; } @ele;
my $atom4subgrp1 = scalar grep { $_ == 1 } @ele;
my $atom4subgrp2 = scalar grep { $_ == 2 } @ele;


#my @sorted = sort @dlp_element;#for the same formula element order  
my %setting = (
    template_file => "$temp_file",
    dlp_element => [@dlp_element], 
    subgrpNum => $subgrpNum,
    subgrp1_ele => ["Te"],
    atom4subgrp1 => $atom4subgrp1,#for L12, the atom number is different 
    subgrp2_ele => ["Sn","Pb"],
    atom4subgrp2 => $atom4subgrp2,
    max_dataNo => 30 , #upper bound number of generated data files
    starting_number => 0, #if 0 number of a element is required
    deduct4max => 0, #The max atom number you want to set by deducting this number. 0 for the max
    last_element_max => 100 #The max atom number of the last element you can assign
); 

my @ele4atomNo_set;#array ref for different element numbers of a subgroup
my $dataNuCount = 1000000;#super large value for while loop works first
my $incr = 0;# increment to increase atom number of an element
my $end_index = 0;
while ($end_index == 0){
    $incr+=1;
    my @template;#all possible atom number of an element, same for all subgrp
    my @subgrp_ratioset;#all ratio set for a subgrp
    #make template array for atom numbers of different subgrp
    for my $grp (1..$setting{subgrpNum}){
        my $grpname2num = "atom4subgrp$grp";
        my $grp_1 = $grp - 1;#array id
        for(my $i = $setting{starting_number}; $i <= $setting{$grpname2num} - $setting{deduct4max} ; $i = $i + $incr){
            push @{$template[$grp_1]},$i;
        }
    }#end of making template arrays for each subgrp

    for my $grp (1..$setting{subgrpNum}){
        my $grpname_ele = "subgrp$grp"."_ele",
        my $grpname2num = "atom4subgrp$grp";
        my $eleNo = @{$setting{$grpname_ele}};#in the suubgrp
        my $grp_1 = $grp - 1;#array from 0
        if($eleNo == 1){#only one element in this group, give all atom number
            push @{$subgrp_ratioset[$grp_1]},[$setting{$grpname2num}];        
        }
        else{#more than one elements in the subgrp
            my $eleNo_1 = $eleNo - 1;
            #print "@{$template[$grp_1]}\n";
            my $iter = variations_with_repetition(\@{$template[$grp_1]},$eleNo_1);
            while (my $p = $iter->next) {
                #print "@{$p}\n";
                my $sum = sum(@{$p});#need smaller than the total number
                if($sum < $setting{$grpname2num}){
                    my $lasteleNu = $setting{$grpname2num} - $sum;
                    chomp $lasteleNu;
                    next if($lasteleNu > $setting{last_element_max} or $lasteleNu < $setting{starting_number});
                    my @temp = (@{$p},$lasteleNu);
                    push @{$subgrp_ratioset[$grp_1]},[@temp];
                }
                elsif($sum == $setting{$grpname2num} and $setting{deduct4max} == 0){
                    my @temp = (@{$p},0);#number of last element is 0                    
                    push @{$subgrp_ratioset[$grp_1]},[@temp];
                }
            }#end of while loop
        }# end of if-else      
    }# end of $subgrp_ratioset loop (for all element number combinations in subgrp)
    # getting the multiply number of all subgrps
    my $multiply = 1;
    print "***increment: $incr\n";    
    for my $grp (1..$setting{subgrpNum}){
        my $grp_1 = $grp - 1;#array id
        print "subgrp $grp combination number: ". @{$subgrp_ratioset[$grp_1]} . "\n";
        $multiply *= @{$subgrp_ratioset[$grp_1]};        
    }#end of making template arrays for each subgrp
    print "Multipy combinations: $multiply, Current setting for max_dataNo: $setting{max_dataNo}\n\n";
    
    #making data files if the criterion is ok.
    if($multiply <= $setting{max_dataNo}){
        my @all_com;#all combinations of all subgrp
        if($setting{subgrpNum} == 1){
            for my $grp1 (@{$subgrp_ratioset[0]}){
                my $temp = "subgrp1:\n"."@{$setting{subgrp1_ele}}\n"."@{$grp1}\n\n";
                push @all_com,$temp;
            }
        }
        elsif($setting{subgrpNum} == 2){
            for my $grp1 (@{$subgrp_ratioset[0]}){
                my $temp = "subgrp1:\n"."@{$setting{subgrp1_ele}}\n"."@{$grp1}\n\n";
                for my $grp2 (@{$subgrp_ratioset[1]}){
                    my $temp_subgrps = "$temp" . 
                    "subgrp2:\n"."@{$setting{subgrp2_ele}}\n"."@{$grp2}\n\n";
                    push @all_com,$temp_subgrps;
                }
            }
        }
        else{
            die "***Currently only two subgrps are considered in this script!!!\n";
        }
       
        my %input_para = (
           template_file => $setting{template_file},           
           dlp_element => $setting{dlp_element},           
           subgrpNum => $setting{subgrpNum},
           subgrpInfo => $setting{subgrpNum}
        ); 

        for my $i (@all_com){
            $input_para{elem_info} = $i;
            &make_input(\%input_para);
            system("perl makedata4QE.pl");#genrate all data files with DLP element types (may have unused ones)
            `cp ./output.data ./output.data-ori`;
            system("perl Mod_data_eleType.pl ./output.data");#remove unused elements in masses and re_assign elm id
            
            ####assign filename 
            my $atomn = `grep atoms ./output.data|awk '{print \$1}'`;
            chomp $atomn;
            my $typen = `grep types ./output.data|awk '{print \$1}'`;
            $typen =~ s/^\s+|\s+$//g;
            print "\$typen: $typen\n";
            #element symbol 
            my @ele = `grep -v '^[[:space:]]*\$' ./output.data|grep -A $typen Masses|grep -v Masses|grep -v -- '--'|awk '{print \$NF}'`;
            map { s/^\s+|\s+$//g; } @ele;
            die "No Masses for finding element symbol in $i\n" unless(@ele);

            #get all element id of atoms
            my @typeinfo = `grep -v '^[[:space:]]*\$' ./output.data|grep -A $atomn Atoms|grep -v Atoms|grep -v -- '--'|awk '{print \$2}'`;
            map { s/^\s+|\s+$//g; } @typeinfo;
            #my @elem = @{$setting{dlp_element}};#all DLP elements
            my %eleNu;
            @eleNu{@ele} = map {0} @eleNu{@ele};

            #for my $i (keys %eleNu){
            #    print "$i --> $eleNu{$i}\n";
            #}
            my %type2elem;
            @type2elem{1..@ele} = @ele;
            my $c = 0;
            for my $i (@typeinfo){
                my $ele = $type2elem{$i};
                $eleNu{$ele}++;                
            }
            #make prefix of data file
            my $prefix = "";
            for my $e (@ele){
                #if($eleNu{$e} != 0){
                    $prefix = "$prefix" . "$e" . "$eleNu{$e}";
                #}
            }
            print "prefix: $prefix\n";
            my $out_file = "$currentPath/ele4ratio/$prefix"."_$plane.data";           
            #`cp output.data-ori  $out_file-ori`;
            `mv ./output.data-ori  $out_file`;
        }       
        $end_index = 1;#end of this while loop
    }
    else{
        next;
    }#not 
    
    #making all data files

}#end of while loop
} #loop of all data files
#####here doc for data file##########
sub make_input
{

my ($input_hr) = @_;

my $input = <<"END_MESSAGE";
#You have to follow the following format!space after ":"

template_file:
$input_hr->{template_file}

#element sequence in DLP
dlp_element:
@{$input_hr->{dlp_element}}

#subgroup information,element group, numbers
subgrpNum:
$input_hr->{subgrpNum}

$input_hr->{elem_info}
END_MESSAGE

#my $file = $lmp_hr->{output_script};
open(FH, '>', "input.txt") or die $!;
print FH $input;
close(FH);
}