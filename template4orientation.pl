#find your own template
#https://atomsk.univ-lille.fr/tutorial_unitcells.php
#https://atomsk.univ-lille.fr/doc/en/mode_create.html

#

use strict;
use warnings;
use Cwd; #Find Current Path
use POSIX;
use lib './';#assign pm dir
use elements;#all setting package

my $currentPath = getcwd(); #get perl code path

my @DLP_elements = ("Pb","Sn","Te");# your DLP elements with the correct order
my $DLP_elementNo  = @DLP_elements;
my %element2mass;#element symbol to its bulk density 
for (@DLP_elements){
    chomp;
    die "no information of element $_ in elements.pm\n" unless (&elements::eleObj("$_"));
    $element2mass{$_} = ${&elements::eleObj("$_")}[2];#mass
}

my $mass = "\nMasses\n\n";
for (1..@DLP_elements){
    my $temp_ele = $DLP_elements[$_ -1];
    my $temp_mass = $element2mass{$temp_ele};
    $mass = "$mass" . "$_ $temp_mass # $temp_ele \n";
}

#the following for rocksalt template data files in atomsk
my @myelement = sort("Co","Cr"); # elements for atomsk only instead of your DLP elements
my $elemNo = @myelement;
my $structure = "rocksalt";                            
my @allorient = ("[010] [001] [100],2 1 2",
                "[001] [1-10] [110],2 2 2",
                "[1-21] [10-1] [111],2 2 1");
#end of atomsk setting     

my $foldername = "$currentPath/" . "template_data"; #folder to keep all generated files
system("mkdir -p $foldername"); # create a new folder
system("rm -rf $foldername/*");
my $crystal = "$structure 2.8665 @myelement";# crystal information:https://atomsk.univ-lille.fr/doc/en/mode_create.html
# end of initial setting

for my $line (@allorient){
    (my $orient,my $dup)  = split(',' ,$line); 
	my $tpori = (split(' ' ,$orient))[2];
	(my $ori) = ($tpori =~ /(\d+)/);
	#system("atomsk --create fcc 3.597 Cu orient [110] [-110] [001] -dup 3 3 3 template.lmp");
	system("atomsk --create $crystal orient $orient -dup $dup $foldername/$structure-$ori.lmp");
    `sed -i 's/[0-9]*[[:space:]]\\+atom types/$DLP_elementNo atom types/' $foldername/$structure-$ori.lmp`;

    my @Atoms = `grep -A30000 "Atoms" $foldername/$structure-$ori.lmp`;
    map { s/^\s+|\s+$//g; } @Atoms; 
    die "No Atoms info found in $foldername/$structure-$ori.lmp" unless (@Atoms); 
    my $Atoms = join("\n",@Atoms);
  
    my @system = `grep -B30000 "Masses" $foldername/$structure-$ori.lmp|grep -v 'Masses'`;
    map { s/^\s+|\s+$//g; } @system; 
    die "No system info found in $foldername/$structure-$ori.lmp" unless (@system); 
    my $system = join("\n",@system);
    #for (@system) {print "$_\n";}
    #die;
    my $temp_data = "$system\n"."$mass\n"."$Atoms\n";
    open(FH, '>', "$foldername/$structure-$ori.lmp") or die $!;
    print FH $temp_data;
    close(FH);
	system("mv $foldername/$structure-$ori.lmp $foldername/$structure-$ori.data");
}

print "Done!!\n";