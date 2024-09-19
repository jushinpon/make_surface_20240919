#nohup perl  &
use strict;
use warnings;
use Cwd;
use POSIX;
#use lib '.';
#use elements;
#unlink "QEbyMatCld_summary.txt";
#open(my $DATA, ">QEbyMatCld_summary.txt");
#
#unlink "MatCld_crawling.txt";
#open(my $DATA1, ">MatCld_crawling.txt");
my $surface = "yes";#if your QE input is for a slab model instead of an unit cell.
my $currentPath = getcwd();
my @QEin_MC = `find $currentPath/QEinByMatCld -name "*.in"`;
chomp @QEin_MC;

`rm -rf QE_trimmed`;
`mkdir QE_trimmed`;
#print $DATA1 "###Crawling QE input from Materials Cloud for:\n\n";
my $total = @QEin_MC;
my $counter = 0;
for my $qe (@QEin_MC){
    $counter++;
    my @magnet = `grep starting_magnetization $qe`;
    map { s/^\s+|\s+$//g; } @magnet;
    my $ntype = @magnet;
    my @pot = `grep -v '^[[:space:]]*\$' $qe|grep -A $ntype ATOMIC_SPECIES|grep -v ATOMIC_SPECIES|grep -v -- '--'`;
    map { s/^\s+|\s+$//g; } @pot;
    my $kpoint = `grep -v '^[[:space:]]*\$' $qe|grep -A 1 K_POINTS|grep -v K_POINTS`;
    $kpoint =~ s/^\s+|\s+$//g;
    #print "$counter: $qe\n";
    #print "@magnet\n";
    #print "@pot\n";
    #print "$kpoint\n\n";
    #read the corresponding template
    my $QEin_name = `basename $qe`;
    $QEin_name =~ s/^\s+|\s+$//g;
    open my $in ,"< data2QE4MatCld/$QEin_name" or die "No data2QE4MatCld/$QEin_name";      
    my @QE_template =<$in>;
    close $in;
    map { s/^\s+|\s+$//g; } @QE_template;
    my $prefix = $QEin_name;
    $prefix =~ s/\.in//g;
    # find the key lines to modify
    my $pl;#id number with ATOMIC_SPECIES
    my $kl;#id number with K_POINTS
    my @start_mag;#ids with starting_magnetization

    for my $id (0..$#QE_template){
        if($QE_template[$id] =~ /ATOMIC_SPECIES/){
            $pl = $id;
        }
        elsif($QE_template[$id] =~ /K_POINTS/){
            $kl = $id;
        }
        elsif($QE_template[$id] =~ /starting_magnetization/){
            push @start_mag,$id;
        }
    }
    #begin trimming
    #pot
    for my $i (0 .. $ntype -1){
        $QE_template[$pl+$i+1] = $pot[$i];
    }
    #kpoint
    if($surface eq "yes"){
        my @temp = split(/\s+/,$kpoint);
        $temp[2] = 1;
        my $temp = join(" ",@temp);
        $QE_template[$kl + 1] = $temp;
    }
    else{
        $QE_template[$kl + 1] = $kpoint;
    }
   #mag
     for my $i (0 .. $ntype -1){
        my $temp = $start_mag[$i];
        $QE_template[$temp] = $magnet[$i];
    }
    my $trimmed = join("\n",@QE_template);
    chomp $trimmed;
    open(FH, ">QE_trimmed/$QEin_name" ) or die $!;
    print FH $trimmed;
    close(FH);
    `rm -rf QE_trimmed/$prefix`;
    `mkdir QE_trimmed/$prefix`;
    `mv QE_trimmed/$QEin_name QE_trimmed/$prefix/`;
}
#unlink "input.in";
#unlink "output.in";
#
#print "\n***Pleae check QEbyMatCld_summary.txt or the following content of QEbyMatCld_summary.txt:\n";
#print "\n***printing QEbyMatCld_summary.txt!!!\n";
#system("cat ./QEbyMatCld_summary.txt");
#print "\n\n*** If the above is empty, All QEinput files are good using Materials Cloud.\n";
