#!/usr/bin/perl
=b
perl Mod_data_eleType.pl input.data 
you will get output data file with used element type number, and modified 
element id for each atom, which is for QE input file
=cut
use strict;
use Cwd;
use Data::Dumper;
use JSON::PP;
use Data::Dumper;
use List::Util qw(min max);
use Cwd;
use POSIX;
use Parallel::ForkManager;

###parameters to set first
my $currentPath = getcwd();# dir for all scripts
chdir("..");
my $mainPath = getcwd();# main path of Perl4dpgen dir
chdir("$currentPath");
die "No input data file path for this Perl script. Use perl Mod_data_eleType.pl "."input.data\n" unless($ARGV[0]);
my $input_data = $ARGV[0];
my %myelement;#get all element symbols you assign (could more than used element number in MD)
#1  atom types
my $typeNum = `grep "atom types" $input_data|awk '{print \$1}'`;
$typeNum =~ s/^\s+|\s+$//g;
#1   58.93319500             # Co
my @ele = `grep -v '^[[:space:]]*\$' $input_data|grep -A $typeNum Masses|grep -v Masses|grep -v -- '--'|awk '{print \$NF}'`;
#my @ele = `grep -v '^[[:space:]]*\$' $_|grep -A $typeNum Masses|grep -v Masses|grep -v -- '--'|awk '{print \$NF}'`;
map { s/^\s+|\s+$//g; } @ele;
die "No Masses for finding element symbol in $_\n" unless(@ele);
# element --> id - 1
my %myelement = map { $ele[$_] => $_ } 0 .. $#ele;

#@myelement{@ele} = 1;
#my @myelement = keys  %myelement;
#map { s/^\s+|\s+$//g; } @myelement;
#die "No elements were found in $input_data\n" unless (@myelement);
my $atomNum = `grep "atoms" $input_data|awk '{print \$1}'`;
$atomNum =~ s/^\s+|\s+$//g;
#1   58.93319500             # Co

#1 3 -4.121844819977641 -2.379748216371669 -2.9145844232047162
my @atom_info4elem = `grep -v '^[[:space:]]*\$' $input_data|grep -A $atomNum Atoms|grep -v Atoms|grep -v -- '--'|awk '{print \$2}'`;

map { s/^\s+|\s+$//g; } @atom_info4elem;
my %used_elem;
for (0 .. $#atom_info4elem){
    my $temp = $atom_info4elem[$_] - 1;
    $used_elem{$ele[$temp]} = 1;
    #print "$_: $atom_info4elem[$_] $ele[$temp]\n";
}

my @final_ele;
my %final_ele2id;
my $count = 0;
for my $e (@ele){
    if(exists $used_elem{$e}){
        $count++;
        #get string with element
        #`grep -v '^[[:space:]]*\$' $input_data|grep -A $atomNum Atoms|grep -v Atoms|grep -v -- '--'|awk '{print \$2}'`
        #my $temp =qx(grep -v '^[[:space:]]*\\$' $input_data | grep -A $typeNum Masses | grep -v Masses | grep $e);
        my $temp = `grep -v '^[[:space:]]*\$' $input_data|grep -A $typeNum Masses|grep -v Masses|grep $e`;
        $temp =~ s/^\s+|\s+$//g;
        #print "\$temp: $temp\n";
        my @temp = split(/\s+/, $temp);
        $temp[0] = $count;
        my $string = join(" ",@temp);
        push @final_ele,$string;
        $final_ele2id{$e} = $count; #element symbol to element id
    }
}

my $masses = join("\n",@final_ele);
#print "$masses\n";

my @atoms = `grep -v '^[[:space:]]*\$' $input_data|grep -A $atomNum Atoms|grep -v Atoms|grep -v -- '--'`;
map { s/^\s+|\s+$//g; } @atoms;
#$ele[$temp] --> original id - 1 --> element symbol
#$final_ele2id{$e}

for my $a (0..$#atoms){
    #print "$a: $atoms[$a]\n";
    my @temp = split(/\s+/, $atoms[$a]);
   # print "1. $atoms[$a]\n";
    my $ele = $ele[$temp[1] - 1];
    my $mod_id = $final_ele2id{$ele};
    $temp[1] = $mod_id;
    my $string = join(" ",@temp);
    $atoms[$a] = "$string";    
}
my $atoms = join("\n",@atoms);

my $xcell = `grep xlo $input_data`;
$xcell =~ s/^\s+|\s+$//g;
my $ycell = `grep ylo $input_data`;
$xcell =~ s/^\s+|\s+$//g;
my $zcell = `grep zlo $input_data`;
$zcell =~ s/^\s+|\s+$//g;
my $xycell = `grep xy $input_data`;
$xycell =~ s/^\s+|\s+$//g;
unless($xycell){$xycell = "0.00 0.00 0.00 xy xz yz";}

chomp($xcell,$ycell,$zcell,$xycell);
my @cell = ($xcell,$ycell,$zcell,$xycell);
my $cell = join("\n",@cell);

my $atomNo = @atoms;
my $eleNo = @final_ele;

my $here_doc =<<"END_MESSAGE";
# LAMMPS data file written by OVITO Basic 3.7.8

$atomNo atoms
$eleNo atom types

$cell

Masses

$masses

Atoms  # atomic

$atoms
END_MESSAGE

open(FH, "> output.data") or die $!;
print FH $here_doc;
close(FH);