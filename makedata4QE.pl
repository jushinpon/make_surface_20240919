use strict;
use warnings;
use POSIX;
use List::Util qw(shuffle);

my $data_dir = "./";
my $template = `grep -A 1 template_file: ./input.txt|grep -v template_file:`;
chomp $template;

my $atomn = `grep atoms ./$template|awk '{print \$1}'`;
chomp $atomn;

my $elements = `grep -A 1 dlp_element: ./input.txt|grep -v dlp_element:`;
$elements =~ s/^\s+|\s+$//g;

my @DLPele=(split(/\s+/,$elements));#element sequence in dlp training

my %lmpId;
@lmpId{@DLPele} = 1..$#DLPele + 1;#id in lammps

#arrange type 
my $subnum =  `grep -A 1 subgrpNum: ./input.txt|grep -v subgrpNum:`;
chomp $subnum;

my %subgrp;#[elements],[numbers] $subgrp{1} = [["Al","Cr"],[9,18]];
for (1..$subnum){
    my $temp = "subgrp$_:";
    my @temp =  `grep -A 2 $temp ./input.txt|grep -v $temp`;
    $subgrp{$_} = [[split(/\s+/,$temp[0])],[split(/\s+/,$temp[1])]];
}

my %type;#types for subgroup
for my $t (1 .. keys %subgrp){
    my @elem = @{$subgrp{$t}->[0]};#elements
    my @num = @{$subgrp{$t}->[1]};#element numbers
    for my $l (0..$#num){
        my $lmpId = $lmpId{$elem[$l]};
        push @{$type{$t}}, $lmpId for (1..$num[$l]);
    }
}

for (sort keys %type){
    @{$type{$_}} = shuffle(@{$type{$_}});
}

#get first part of data file
my @part1 = `grep -B 1000 "Atoms" ./$template|grep -v Atoms`;
map { s/^\s+|\s+$//g; } @part1;
my $part1 = join("\n",@part1);
chomp $part1;

#get atomid
my @atomid = `grep -v '^[[:space:]]*\$' ./$template|grep -A $atomn Atoms|grep -v Atoms|grep -v -- '--'|awk '{print \$1}'`;
map { s/^\s+|\s+$//g; } @atomid;
#get typeid
my @typeid = `grep -v '^[[:space:]]*\$' ./$template|grep -A $atomn Atoms|grep -v Atoms|grep -v -- '--'|awk '{print \$2}'`;
map { s/^\s+|\s+$//g; } @typeid;

#modify typeid
my %count;
for (keys %type){$count{$_} = 0;}
for my $i (0..$#typeid){    
    my $ori = $typeid[$i];#original type to be modified
    my $id  = $count{$ori};
    $typeid[$i] = ${$type{$ori}}[$id];
    $count{$ori}++;   
}

#get coordinate information
my @coordinates = `grep -v '^[[:space:]]*\$' ./$template|grep -A $atomn Atoms|grep -v Atoms|grep -v -- '--'`;
map { s/^\s+|\s+$//g; } @coordinates;

for (0..$#coordinates){
    my @temp = split(/\s+/,$coordinates[$_]);
    $temp[1] = $typeid[$_];
    $coordinates[$_] = join(" ",@temp);
    chomp $coordinates[$_];
}

my $coords = join("\n",@coordinates);

my $here_doc =<<"END_MESSAGE";
$part1

Atoms  # atomic

$coords
END_MESSAGE

unlink "./output.data";
open(FH, "> ./output.data") or die $!;
print FH $here_doc;
close(FH);