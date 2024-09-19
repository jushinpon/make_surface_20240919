use strict;
use warnings;

die "Don't use this script directly!!! ONly to guide you the whole sequenece of ".
"all required perl scripts for make planes with different orientation!\n";

#1. template4orientation.pl: make your template data files with orientaions you want in z dimension. (unit cell)
#output folder: template_data

#2. gendata4ratio.pl: generate data files with different element compositional fractions
#output folder: ele4ratio 

#3. data4density.pl: modify the boxes of all data files for adjusting the system densities to approximate ones. 
#output folder: den_mod

#It's better to do the vc-relax for all structures in den_mod before adding vacuum 

#4. add_vacuum.pl: add vacuum in z dimension for all data files in den_mod
#output folder: add_vacuum

#5. data2QE4MatCld.pl: convert all data fiels in add_vacuum into QE input for getting k-points using materials cloud tool
#output folder: data2QE4MatCld

#6.  QEinputByMatCld.pl: QE input by materials cloud tool (conducting Web scraping, could take some time!)
#output folder: QEinByMatCld

#7. QEinTrim.pl: modify QE kpoint using those from materials cloud tool
#output folder: QE_trimmed 

#8.  ModQEsetting.pl: final setting for all your QE input files
#output folder: QEall_set

# You are almost ready to submit your QE jobs!!!!

#make_slurm_sh.pl: make all slurm sh files for your QE cases.
# submit_allslurm_sh.pl: submit all your QE cases using sh files. 