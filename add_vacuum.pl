#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
use POSIX;
use lib './';#assign pm dir
use elements;#all setting package

###parameters to set first
my $currentPath = getcwd();
my $vacuum_z = 10.0; # vacuum in z

`rm -rf $currentPath/add_vacuum`;#remove old data
`mkdir -p  $currentPath/add_vacuum`;
my $data_dir = "$currentPath/den_mod";#you may assign yours 
my @datafile = `find $data_dir -name "*.data"`;#find all data files
map { s/^\s+|\s+$//g; } @datafile;
die "No data files\n" unless(@datafile);

for (@datafile){
    my $filename =`basename $_`;#get path
    $filename =~ s/^\s+|\s+$//g;
    `cp $_ $currentPath/add_vacuum/$filename`;
    
#sed -i 's/\([-0-9\.eE]\+\) \([-0-9\.eE]\+\) zlo zhi/\1 19.098472202626079 zlo zhi/' test.data

    my $zhi_value = `grep "zlo zhi" $currentPath/add_vacuum/$filename|awk '{print \$2}'`;
    $zhi_value =~ s/^\s+|\s+$//g;
    $zhi_value = $zhi_value + $vacuum_z;
    # Define the sed command with escape sequences for Perl
    my $sed_command = "sed -i 's/\\([-0-9\\.eE]\\+\\) \\([-0-9\\.eE]\\+\\) zlo zhi/\\1 $zhi_value zlo zhi/' $currentPath/add_vacuum/$filename";

# Use Perl's system function to run the sed command
    system($sed_command) == 0 or die "System call failed: $!";
   
}#all data files

