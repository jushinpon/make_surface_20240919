use warnings;
use strict;
use Cwd;

my $currentPath = getcwd();
my $QE_folder = "QE_trimmed";#folder where you place all your QE input files
my $out_folder = "QEall_set";#folder having all subfolders (the same prefixes as QE input file) with the QE input
`rm -rf $currentPath/$out_folder`;
`mkdir $currentPath/$out_folder`;
## set Temperature and press 
my @tempw = (300);
my @press = (0);
my %para =(#you may set QE parameters you want to modify here. Keys should be the same as used in QE
    calculation => '"vc-md"',
    cell_dofree => '"2Dxy"',
    cell_dynamics => '"pr"',
    #vdw_corr => '"DFT-D3"', #use Van der Waals
    dt => 50,
    nstep => 100,
    etot_conv_thr => "1.0d-5",#perl not know d-5, make it a string 
    forc_conv_thr => "1.0d-4",
    disk_io => '"none"',
    degauss =>   0.035,
    smearing => '"gaussian"',
    conv_thr =>   "2.d-5",
    mixing_beta =>   0.2,
    mixing_mode => '"local-TF"',# !'plain'
    mixing_ndim => 8,# !set 4 or 3 if OOM-killer exists (out of memory)
    diagonalization => '"david"',#!set cg if if OOM-killer exists (out of memory). other types can be used for scf problem.
    diago_david_ndim => 2,
    electron_maxstep => 300
);

my @keys = keys %para;#get all keys 

my @allQEin = `find $currentPath/$QE_folder -type f -name "*.in"`;#all QE template files
map { s/^\s+|\s+$//g; } @allQEin;

for my $f (@allQEin){
    my $data_path = `dirname $f`;
    my $data_name = `basename $f`;
    $data_name =~ s/\.in//g;
    chomp ($data_path, $data_name);
    #load QE_template file to trim
    open my $in ,"< $f" or die "No $f";      
    my @QE_template =<$in>;
    close $in;
    map { s/^\s+|\s+$//g; } @QE_template;

    # perturb all coordinates with 0.05    
    for my $c (0 .. $#QE_template){
        if($QE_template[$c] =~ /(\D{1,2})\s+([+-]?\d*\.*\d*)\s+([+-]?\d*\.*\d*)\s+([+-]?\d*\.*\d*)/
         and $4 ne "" and $3 ne "" and $2 ne "" and $1 ne ""){
            my $c1 = sprintf("%.6f",$2 + (2.0*rand() -1.0) * 0.05);
            my $c2 = sprintf("%.6f",$3 + (2.0*rand() -1.0) * 0.05);
            my $c3 = sprintf("%.6f",$4 + (2.0*rand() -1.0) * 0.05);
            $QE_template[$c] = "$1 $c1 $c2 $c3";
            chomp $QE_template[$c];
        }
    }

    my @keylines;
    #modify some settings first
    for my $k (@keys){
        for my $kl (0..$#QE_template){
            if($QE_template[$kl] =~ /^\!?$k/){
                $QE_template[$kl] = "$k = $para{$k}";
                last;
            }
        }
    }
    # the above settings have been done. 
    for my $t (@tempw){
        for my $p (@press){
            for my $kl (0..$#QE_template){
                if($QE_template[$kl] =~ /tempw/){
                    $QE_template[$kl] = "tempw = $t";                    
                }
                elsif($QE_template[$kl] =~ /press/){
                     $QE_template[$kl] = "press = $p";
                }
            }#T and P done!
            # make a folder to write into

            my $foldname = "$data_name-T$t-P$p";
            `mkdir -p $currentPath/$out_folder/$foldname`;
            my $trimmed = join("\n",@QE_template);
            chomp $trimmed;
            open(FH, ">$currentPath/$out_folder/$foldname/$foldname.in" ) or die $!;
            print FH $trimmed;
            close(FH);
        }
    }
}



