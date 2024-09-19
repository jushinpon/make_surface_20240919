=b
filter required data files and collect them into data4relax folder.
=cut
use strict;
use warnings;
use Cwd;
use POSIX;
#
my $currentPath = getcwd();
my $source_folder = "QE_trimmed4relax";
my $data_folder = "data_files";

my @QEout_folders = `find $currentPath/$source_folder -maxdepth 1 -mindepth 1 -type d`;#find all folders 
#my @QEout_folders = `find $currentPath/$source_folder -type d -name "*"`;#find all folders
map { s/^\s+|\s+$//g; } @QEout_folders;
die "No folders were found under the source folder, $source_folder\n" unless(@QEout_folders);
#print "@QEout_folders\n";
`rm -rf data4md_relaxed`;
`mkdir data4md_relaxed`;
open(my $FH, "> data4md_relaxed/No_data.txt") or die $!;
print $FH "## The following are cases with No data files to deal with! (none is ok for all)\n\n";

for my $f (@QEout_folders){
    my @data_files = `ls $f/$data_folder/*.data`;
    map { s/^\s+|\s+$//g; } @data_files;
    if(@data_files){
        my $prefix = `basename $f`;
        $prefix =~ s/^\s+|\s+$//g;
        `cp $data_files[-1] $currentPath/data4md_relaxed/$prefix.data`;
    }
    else{
        print "no data files in $f\n";
        print $FH "$f\n";
    }   
}
close($FH);
system("cat data4relax/No_data.txt");
print "\n\n!!!If all folders are listed, maybe you forget to conduct perl /opt/qe_perl/QEout2data.pl in advance.\n";