#! /usr/bin/perl -w
#
######################################################################################################
#
# Description:	Purges old files on a given filesystem.
#
# Usage:	purge.pl [ -f ]
#
#		where "-f" forces a purge, regardless of when
#		the last purge occurrered, and regardless of the
#		amount of available disk space.
#
# "purge.pl" (purge periodic) is run hourly by cron (as root) to purge
# /data/scratch disk space.  At least one purge is run daily.  If space is
# tight, a shorter purge period is used and it will purge more
# than once a day.
#
# A log is written that contains the df output before and after and
# a list of the removed files.
#
# This file is executed out of /root/src/purge-script/832data.pl
#
# This script must be run by root or a superuser.
#
# Long NQS jobs can run longer than the 3/4 day limit for purge.  Thus, files 
# can be deleted from under a NQS job.  To prevent this users that are in NQS
# are excluded from purge.
#
# If the format of "llq" changes the script will need to be fixed.
#
######################################################################################################
#
### use diagnostics -verbose;
#
### use strict;
### use strict "vars";
    use strict "refs";
### use strict "subs";
#
use English;
use FileHandle;
#
$OUTPUT_AUTOFLUSH = 1;
autoflush  STDOUT   1;
autoflush  STDERR   1;
#
######################################################################################################
#
if (defined($ENV{"PURGE_DEBUG"})) {
    $debug = $ENV{"PURGE_DEBUG"};
} else {
    $debug = 1;                               ### default debug level (0=off)
} #end_if
#
if (defined($opt_d)) {
    $debug = 1;
} #end_if
#
######################################################################################################
#
umask(022);
#
######################################################################################################
#
# ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat(filename);
#
undef($atime);
undef($blksize);
undef($blocks);
undef($ctime);
undef($dev);
undef($gid);
undef($ino);
undef($mode);
undef($mtime);
undef($nlink);
undef($rdev);
undef($size);
undef($uid);
#
######################################################################################################
#
# ($sec,$min,$hour,$mday,$month0,$yy,$wday,$yday,$isdst) = gmtime($BASETIME);
#
undef($hour);
undef($isdst);
undef($mday);
undef($min);
undef($month);
undef($month0);
undef($sec);
undef($wday);
undef($yday);
undef($year);
undef($yy);
#
######################################################################################################
#
# use Getopt::Long;
#
# use Getopt::Std;
#
# use Getopt;
# use Getopts;
#
# $result = GetOptions("df");
#
# getopt('df');
#
undef($opt_d);
undef($opt_f);
Getopts('df');
#
######################################################################################################
#
if (-e "/etc/nologin") {
    exit(0);
} #end_if
#
######################################################################################################
#
undef(@days_in_month0);
# month (base 0)    0  1  2  3  4  5  6  7  8  9 10 11
@days_in_month0 = (31,28,31,30,31,30,31,31,30,31,30,31);
#
undef(@days_in_month1);
# month (base 1)       1  2  3  4  5  6  7  8  9 10 11 12
@days_in_month1 = (-1,31,28,31,30,31,30,31,31,30,31,30,31);
#
undef(@day_name);
@day_name = ("Sun","Mon","Tue","Wed","Thu","Fri","Sat");
#
undef(@month_name0);
undef(@month_name1);
@month_name0 = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
#                0     1     2     3     4     5     6     7     8     9     10    11
@month_name1 = ( -1  ,"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
#                      1     2     3     4     5     6     7     8     9     10    11    12
#
$ENV{"TZ"} =  "PST8PDT";
@zone_name = ("PST","PDT");  # Pacific Standard Time / Pacific Daylight savings Time
#
$local_time = ts($BASETIME); # like `/bin/date "+%Y%m%d_%H%M%S_%Z_%a"`; ### CCYY.MM-Mon.DD-Day_HH:MM:SS-Zon
#
$ENV{"TZ"} =  "CUT0";
@zone_name = ("CUT","GMT"); # Coordinated Universal Time or Greenwich Mean Time (or UTC)
#
$cut_time = ts($BASETIME);  # Example: 1997.05-May.06-Fri_02:13:06-CUT
#
######################################################################################################
#
$ENV{"TZ"} =  "PST8PDT";
@zone_name = ("PST","PDT");  # Pacific Standard Time / Pacific Daylight savings Time
#
# ($sec,$min,$hour,$mday,$month0,$yy,$wday,$yday,$isdst) = gmtime   ($BASETIME);
($sec,$min,$hour,$mday,$month0,$yy,$wday,$yday,$isdst)   = localtime($BASETIME);
#
$month  = $month0 + 1;
$year   = $yy + 1900;
$mm_mon = sprintf("%02d-%3s",$month,$month_name1[$month]);
$dd_day = sprintf("%02d-%3s",$mday,$day_name[$wday]);
#
$timedir = "/" . $year . "/" . $mm_mon . "/" . $dd_day;    # /1997/12_Dec/04_Thu
#
######################################################################################################
#
### if ($month == 1) {
###     $previous_month = "12";
### } else {
###     $previous_month = $month - 1;
### } #end_if
#
### $days_last_month = $days_in_month1[$previous_month];
#
######################################################################################################
######################################################################################################
#
$ENV{PATH} = "/bin:/usr/bin:/usr/sbin:/sbin";                     ### Path environment variable
#
##  sjames not yet  062912
$Free_Space_Limit          = 5;                                 ### force purge if below % free
#
####$Days_to_Purge             = 180.0;                               ### Previously it based on %free disk space
$Days_to_Purge             = 21.0;                               ### Previously it based on %free disk space
$Max_time_since_last_purge = 4.0;                               ### Max time between forced purges, in DAYS
#
$Purge_File_System_name = "scratch";                            ### target file system to purge
$Purge_File_System      = "/data/scratch";                           ### target file system to purge
$Prevent_Purge          = $Purge_File_System . "/no_purge";     ### File if present prevents purge
#
### $Purge_Log_Directory_Top = "/work/Archive/Disk_Purge/" . $Purge_File_System_name;
#
$Purge_Log_Directory_Top = "/data/scratch/log_files/Disk_Purge/" . $Purge_File_System_name; ### Directory logs are created in.
#
$Last_Successful_Purge  = $Purge_Log_Directory_Top . "/last_successful_purge_of_" . $Purge_File_System_name; ### Created every successful force purge
#
$Purge_Log_Directory    = $Purge_Log_Directory_Top . $timedir;
$Purge_Log              = $Purge_Log_Directory . "/" . $local_time . "__" . $Purge_File_System_name . ".log.purge____" . $Days_to_Purge . "_Day_Purge";
$qstat_Log              = $Purge_Log_Directory . "/" . $local_time . "__" . $Purge_File_System_name . ".qstat.info___" . $Days_to_Purge . "_Day_Purge";
$Purged_Files_Log       = $Purge_Log_Directory . "/" . $local_time . "__" . $Purge_File_System_name . ".files.purged_" . $Days_to_Purge . "_Day_Purge";
#
if (-e "$Last_Successful_Purge") {
    $time_since_last_purge = -M "$Last_Successful_Purge";       ### Age of file in days
} else {
    $time_since_last_purge = 999999.999999999;                     ### File does not exist, purge never ran?
} #end_if
#
######################################################################################################
######################################################################################################
#
@groups_to_avoid = ( 
                    "nobody", 
		    "root" 
                   );
@users_to_avoid  = ( 
                    "nobody",
                    "root",
		    "dyparkinson",
		    "eschaible",
		    "hmwood",
		    "kmfernsler",
		    "fernsler",
		    "sjames",
		    "bl832acq",
		    "trushmer",
		    "mholland",
		    "alsdata",
		    "aamacdowell",
		    "bl733",
		    "wgwinegar",
		    "hsbarnard",
		    "fzok",
		    "ychen",
		    "hypersonic"
                   );
#
######################################################################################################
######################################################################################################
#
### pattern ^$Purge_File_System/<paths_to_avoid>
#
# Paths listed below should be relative to $Purge_File_System (/data/scratch).
#
# These paths are ***PERL REGULAR EXPRESSIONS*** indicating path to match.
#
@paths_to_avoid  = (
                    "root",
		    "Disk_Purge",
		    "log_files",
		    "group.quota",
                    "lost+found",
		    "user.quota",
		    "NX_README",
		    "[^/]*/.bashrc",
		    "[^/]*/.bash_history",
		    "[^/]*/.bash_logout",
		    "[^/]*/.bash_profile",
		    "[^/]*/.emacs",
		    "[^/]*/.Xauthority",
		    "aamacdowell",
	            "alsdata",
		    "bl733",
		    "bl832acq",
		    "dyparkinson",
		    "kmfernsler",
		    "fernsler",
		    "eschaible",
		    "trushmer",
		    "mholland",
		    "sjames",
		    "wgwinegar",
		    "ychen",
		    "fzok",
	            "hmwood",
		    "hsbarnard",
		    "hypersonic"
                   );

#		    "/data/scratch/aamacdowell",
#	            "/data/scratch/alsdata",
#		    "/data/scratch/bl733",
#		    "/data/scratch/bl832acq",
#		    "/data/scratch/dyparkinson",
#		    "/data/scratch/eschaible",
#		    "/data/scratch/fzok",
#	            "/data/scratch/hmwood",
#		    "/data/scratch/hsbarnard",
#		    "/data/scratch/hypersonic"

#
######################################################################################################
######################################################################################################
#
### pattern $Purge_File_System/directory/user_named_subdir_to_avoid_anywhere_in_this_directory_tree
#
# These should be user name subdirectories that are created under other user directories.
#
@user_subdir_to_avoid = (
		    "root",
		    "sjames",
		    "alsdata",
		    "fernsler",
		    "kmfernsler",
		    "bl733",
		    "bl832acq",
		    "dyparkinson",
		    "eschaible",
		    "fzok",
		    "hmwood",
		    "hsbarnard",
		    "hypersonic"
		);

#
######################################################################################################
######################################################################################################
#
$df = "/bin/df";
$df_opts = "-P -k " . $Purge_File_System . "/.";
#
undef($hostname_opts);
$hostname = "/bin/hostname";
$hostname_opts = "";
#
$find = "/usr/bin/find";
$find_opt = $Purge_File_System . " -depth -type f -atime +" . $Days_to_Purge . " -ctime +" . $Days_to_Purge . " -mtime +" . $Days_to_Purge ." ";
#
$mkdir      = "/bin/mkdir";
$mkdir_opts = "-p ";
#
undef($ps_opts);
$ps = "/bin/ps";
$ps_opts = "-o pid,ppid";
#
# commented cuz they don't exist on tg.  --mpackard
#$llq = "/usr/lpp/LoadL/full/bin/llq";
#$llq_opts = "";
#
$qstat = "/usr/bin/qstat";
$qstat_opts = "";
#
$grep = "/bin/grep";
#
foreach $executable ( ( $df , $hostname , $mkdir , $ps , $grep , $qstat) ) {
    if (! -x "$executable") {
        printf(STDERR "###WARNING $executable is not executable.");
    } #end_if
} #end_foreach $executable
#
######################################################################################################
#
@lines = `$hostname`;
$child_error = $CHILD_ERROR;
#
if ($child_error || ($#lines > 0) || ($debug > 1)) {
    $Exit_Status = ($child_error >> 8) & 0xff;
    $Intr_Status = ($child_error       & 0xff);
    printf(STDERR "\#\#\#");
    printf(STDERR "ERROR") if ($child_error || ($#lines >= 0));
    printf(STDERR " exit=%d intr=%d 0x%04x = %s\n",$Exit_Status,$Intr_Status,$child_error,$hostname);
    for ($i = 0 ; $i <= $#lines ; $i++) {
        printf(STDERR "\#\#\# %s:%s: %s",$hostname,$i,$lines[$i]);
    } #end_for $i
    exit($child_error) if ($child_error || ($#lines >= 0));
} #end_if
#
$host = $lines[0];
#
chomp($host);
#
######################################################################################################
#
while (($username, $pw, $uid) = getpwent) {
    $user{$uid} = $username unless $user{$uid};
} #end_while
#
#
######################################################################################################
#
while (($group, $pw, $gid) = getgrent) {
    $group{$gid} = $group unless $group{$gid};
} #end_while
#
######################################################################################################
#
if (! -d "$Purge_Log_Directory/.") {
    @lines = `$mkdir $mkdir_opts $Purge_Log_Directory`;
#
    $child_error = $CHILD_ERROR;
#
    if ($child_error || ($#lines >= 0) || ($debug > 1)) {
        $Exit_Status = ($child_error >> 8) & 0xff;
        $Intr_Status = ($child_error       & 0xff);
        printf(STDERR "\#\#\#");
        printf(STDERR "ERROR") if ($child_error || ($#lines >= 0));
        printf(STDERR " exit=%d intr=%d 0x%04x = %s %s %s\n",
               $Exit_Status,$Intr_Status,$child_error,$mkdir,$mkdir_opts,$Purge_Log_Directory);
        for ($i = 0 ; $i <= $#lines ; $i++) {
            printf(STDERR "\#\#\# %s:%s: %s",$mkdir,$i,$lines[$i]);
        } #end_for $i
        exit($child_error) if ($child_error || ($#lines >= 0));
    } #end_if
} #end_if
#
die("###ERROR You do not have write access to directory $Purge_Log_Directory.") if (! -w "$Purge_Log_Directory/.");
#
system("$find $Purge_Log_Directory_Top -type d -exec /bin/chown dyparkinson:microctstaff \{\}    \\\;");
system("$find $Purge_Log_Directory_Top -type d -exec /bin/chmod u=rwx,g=rwxs,o=rx,+t \{\} \\\;");
#
open(LOG,"> $Purge_Log") or
    die("\#\#\#ERROR Could not create file $Purge_Log for writing.");
autoflush LOG 1;
#
printf(LOG "File system purge utility %s\n",$PROGRAM_NAME);
printf(LOG "##############################################################################\n");
printf(LOG "Hostname              = %s\n",$host);
printf(LOG "Local time            = %s\n",$local_time);
printf(LOG "CUT   time            = %s\n",$cut_time);
printf(LOG "Base  time            = %s\n",$BASETIME);
printf(LOG "Time since last purge = %s\n",$time_since_last_purge);
printf(LOG "Time since last purge = %s (dddd-HHMMSS)\n",dddd_hhmmss($time_since_last_purge));
printf(LOG "Free_Space_Limit      = %s\n",$Free_Space_Limit);
printf(LOG "Purge_File_System     = %s\n",$Purge_File_System);
printf(LOG "Prevent_Purge file    = %s\n",$Prevent_Purge);
printf(LOG "Days to purge         = %s days\n",$Days_to_Purge);
printf(LOG "Real       user id    = %s\n",$REAL_USER_ID);
printf(LOG "Real      group id    = %s\n",$REAL_GROUP_ID);
printf(LOG "Effective  user id    = %s\n",$EFFECTIVE_USER_ID);
printf(LOG "Effective group id    = %s\n",$EFFECTIVE_GROUP_ID);
printf(LOG "Process id            = %s\n",$PROCESS_ID);
#
printf(LOG "##############################################################################\n");
#
######################################################################################################
#
die("###ERROR  File system $Purge_File_System does not exist.") if (! -d "$Purge_File_System/.");
#
######################################################################################################
#
if (-e "$Prevent_Purge") {
   printf("### Presence of file %s prevents purging of file system %s. ###\n",
          $Prevent_Purge,$Purge_File_System) if $debug;
   printf(LOG "### Presence of file %s prevents purging of file system %s. ###\n",
          $Prevent_Purge,$Purge_File_System);
   printf(LOG "Please remove file %s to re-enable file purge for %s.\n",
          $Prevent_Purge,$Purge_File_System);
   close(LOG);
   exit(0);
} #end_if
#
######################################################################################################
#
printf(LOG "\n");
#
if (defined($opt_f)) {
    printf("Force purge of file system %s enabled.  -f option specified on execute line.\n",
           $Purge_File_System) if $debug;
    printf(LOG "Force purge of file system %s enabled.  -f option specified on execute line.\n",
           $Purge_File_System);
    $Force_Purge = 1;                     ### "-f" option present, force purge
} else {
    printf(LOG "Force purge of file system %s was not explicitly requested.\n",
           $Purge_File_System);
    printf(LOG "No -f option was specified on the execute line.\n");
    $Force_Purge = 0;                     ### default is "no force"
} #end_if
#
######################################################################################################
#
# [sp017 98] df -P -k /clusterfs/lawrencium
# Filesystem    1024-blocks      Used Available Capacity Mounted on
# /dev/lv_gpfs     71024640   8964588  62060052      13% /rmount/gpfs
# 0                1          2        3             4   5
#
@lines=`$df $df_opts`;
#
$child_error = $CHILD_ERROR;
#
$line = $lines[1];
chomp($line);
@pieces = split(' ',$line);
#
if ($child_error || ($#lines > 1) || ($#pieces != 5) || ($debug > 1)) {
    $Exit_Status = ($child_error >> 8) & 0xff;
    $Intr_Status = ($child_error       & 0xff);
    printf(STDERR "###");
    printf(STDERR "ERROR") if ($child_error || ($#lines > 0));
    printf(STDERR " exit=%d intr=%d 0x%04x = %s %s\n",$Exit_Status,$Intr_Status,$child_error,$df,$df_opts);
    for ($i = 0 ; $i <= $#lines ; $i++) {
        printf(STDERR "### %s:%s: %s",$df,$i,$lines[$i]);
    } #end_for $i
    exit($child_error) if ($child_error);
} #end_if
#
$percent_used = $pieces[4]; # 13%
if ($pieces[4] =~ m/^(\d+)\%$/) {
    $percent_used = $1;
} else {
    die("###ERROR Could not parse Capacity(%) in $line");
} #end_if
$percent_free = 100 - $percent_used;
#
printf(LOG "\n");
printf(LOG "/bin/df of %s before disk purge.\n",$Purge_File_System);
printf(LOG "%s",$lines[0]);
printf(LOG "%s\n",$line);
printf(LOG "\n");
printf(LOG "Percent free %d %%\n",$percent_free);
printf(LOG "Percent used %d %%\n",$percent_used);
printf(LOG "\n");
#
######################################################################################################
#
# If there is plenty of disk space AND 
#    no force option has been specified on the command line AND 
#    a purge has been done already today
# THEN exit
# ELSE purge
#
if (($percent_free >= $Free_Space_Limit) &&
    ($Force_Purge == 0) &&
    ($time_since_last_purge < $Max_time_since_last_purge)) {
    printf(LOG "NO PURGE WILL BE DONE FOR THE FOLLOWING REASONS:\n");
    printf(LOG "################################################\n");
    printf(LOG "  o  %% free = %s %%, which is >= %s %% (Minimum_Free_Space), and\n",$percent_free,$Free_Space_Limit);
    printf(LOG "  o  Time since last purge is %s (ddd-HH:MM:SS), which is < %s (ddd-HH:MM:SS), and\n",
           dddd_hhmmss($time_since_last_purge),dddd_hhmmss($Max_time_since_last_purge));
    printf(LOG "  o  Force purge (-f) was not specified on the execute line.\n");
    exit(0);
} else {
    printf(LOG "A purge of file system %s will be done for the following reasons.\n",$Purge_File_System);
    printf(LOG "###################################################################\n");
    printf(LOG "  o  %% free = %s %%, which is <= %s %% (Minimum_Free_Space).\n",
           $percent_free,$Free_Space_Limit) if ($percent_free < $Free_Space_Limit);
    printf(LOG "  o  Time since last purge is %s (ddd-HH:MM:SS), which is >= %s (ddd-HH:MM:SS), and\n",
           dddd_hhmmss($time_since_last_purge),dddd_hhmmss($Max_time_since_last_purge))
               if ($time_since_last_purge >= $Max_time_since_last_purge);
    printf(LOG "  o  Force purge (-f) was specified on the execute line.\n") if $Force_Purge;
} #end_if
printf(LOG "\n");
#

### mpackard qstat stuff ###

######################################################################################################
# Build a list of batch users - queued and running
######################################################################################################
# [ds001 512] /usr/lpp/LoadL/full/bin/llq
# Id                       Owner      Submitted   ST PRI Class        Running On
# ------------------------ ---------- ----------- -- --- ------------ -----------
# ds001.29005.0            ux453805    7/18 17:21 R  50  normal       ds229
# ds001.29785.0            ux453739    7/21 18:27 R  50  high         ds257
# ds001.29790.0            ux450945    7/21 18:42 R  50  TGnormal     ds007
# ds001.29791.0            ux450945    7/21 18:42 R  50  TGnormal     ds007
# ds001.29792.0            ux450945    7/21 18:42 R  50  TGnormal     ds008
# ds001.29793.0            ux450945    7/21 18:42 R  50  TGnormal     ds008
# ds001.29794.0            ux450945    7/21 18:42 R  50  TGnormal     ds009
# ds001.29942.0            ux452337    7/22 03:55 R  50  normal       ds165
# ds001.30017.0            ux453890    7/22 12:23 R  50  normal       ds127
# ds001.30028.0            ux455420    7/22 14:12 R  50  normal32     ds010
# ds001.30049.0            ux455253    7/22 16:40 R  50  normal32     ds006
# ds001.30094.0            ux450945    7/22 18:34 R  50  TGnormal     ds009
# ds001.28350.0            ux454188    7/8  21:38 I  50  normal
# 0                        1           2    3     4  5   6            [7]
#
$qstat_exe = $qstat;
$qstat_exe .= " " . $qstat_opts if (defined($qstat_opts) && ($qstat_opts ne ""));
#
# @lines = `$qstat_exe | $grep ' [IR] '`;
@lines = `$qstat_exe`;
#
$child_error = $CHILD_ERROR;
chomp(@lines);
#
if ($child_error || ($debug > 1)) {
    $Exit_Status = ($child_error >> 8) & 0xff;
    $Intr_Status = ($child_error       & 0xff);
    printf(STDERR "\#\#\#");
    printf(STDERR "ERROR") if $child_error;
    printf(STDERR " exit=%d intr=%d 0x%04x = %s %s\n",$Exit_Status,$Intr_Status,$child_error,$qstat,$qstat_opts);
    for ($i = 0 ; $i <= $#lines ; $i++) {
        printf(STDERR "\#\#\# %s:%s: %s",$qstat,$i,$lines[$i]);
    } #end_for $i
    exit($child_error) if $child_error;
} #end_if
#
open(QSTAT,"> $qstat_Log") or
    warn("\#\#\#ERROR Could not open file $qstat_Log for writing");
printf(QSTAT "%s = %s\n\n",$child_error,$qstat_exe);
#
for ($i = 0 ; $i <= $#lines ; $i++) {
# 0                        1           2    3     4  5   6            [7]
# ds001.30094.0            ux450945    7/22 18:34 R  50  TGnormal     ds009
# ds001.28350.0            ux454188    7/8  21:38 I  50  normal

# 0                  1                2                3        4 5
# 103929.dtf-mgmt1   STDIN            ux455386         00:00:02 R dque            
# 103986.dtf-mgmt1   firerad          ux455779         00:02:05 R dque            
# 104109.dtf-mgmt1   runbatch         ux454924                0 Q dque 

    $line = $lines[$i];
    printf(QSTAT "%s\n",$line);
    @pieces = split(' ',$line);
    next if ($#pieces < 5);                                    # not enough fields on line to be what we're looking for
#    next if ($pieces[0] !~ m/ds[0-9][0-9][0-9]\.[0-9]+\.0/i);  # skip if not ds00[0-9].[0-9] type job id
    next if ($pieces[0] !~ m/[0-9]+\.sched-00/i);  # skip if not [0-9].dtf-mgmt1 type job id
#    next if ( ($pieces[4] ne "I") and ($pieces[4] ne "R") and ($pieces[4] ne "ST") );   # skip if not Idle or Running or Starting
    next if ( ($pieces[4] ne "R") and ($pieces[4] ne "H") and ($pieces[4] ne "Q") and ($pieces[4] ne "E") );   # skip if not "running", "queued", "on hold", or "exiting".
#    added by jwhite (could be buggy)
    next if ($pieces[5] !~ m/^lr_.*?$/i);
    $qstat_users{$pieces[2]} = $pieces[0];       # Remember this user
} #end_foreach $line        
#
printf(QSTAT "\nBatch users to avoid:\n");
foreach $key (sort(keys(%qstat_users))) {
    printf(QSTAT "%s\n",$key);
} #end_foreach $key
#
printf(QSTAT "\nAdditional users to avoid:\n");
foreach $key ( sort(@users_to_avoid) ) {
    printf(QSTAT "%s\n",$key);
} #end_foreach $key
#
printf(QSTAT "\nAdditional groups to avoid:\n");
foreach $key ( sort(@groups_to_avoid) ) {
    printf(QSTAT "%s\n",$key);
} #end_foreach $key
#
printf(QSTAT "\nAdditional paths to avoid:\n");
foreach $key ( sort(@paths_to_avoid) ) {
    printf(QSTAT "%s/%s\n",$Purge_File_System,$key);
} #end_foreach $key
#
printf(QSTAT "\n");
foreach $dir (@paths_to_avoid) { 
    $path = $Purge_File_System . "/" . $dir;
    if ( ! -e "$path" ) {
	printf(QSTAT "###INFO  Paths to avoid, %-16s (%-25s), does not exist.\n",$dir,$path);
    } #end_if
} #end_foreach $dir
printf(QSTAT "\n");
#
close(QSTAT);
#

### end mpackard qstat stuff ###


######################################################################################################
# Run the purge 
######################################################################################################
#
#------------------------------------------------------------------------------
# Build find execute line
#------------------------------------------------------------------------------
#
### foreach $group (@groups_to_avoid) {
###     $find_opt .= "! -group " . $group . " ";
### } #end_foreach $group
#
if ($#groups_to_avoid >= 0) {
    $group_filter = ' ! -group ' . join(' ! -group ', sort(@groups_to_avoid) );
} else {
    $group_filter = " ";
} #end_if
#
@qstat_users = sort(keys(%qstat_users));
#
push(@qstat_users,@users_to_avoid);
#
if ($#qstat_users >= 0) {
    $user_filter = ' ! -user ' . join(' ! -user ', sort(@qstat_users) );
} else {
    $user_filter = " ";
} #end_if
#
$find_opt .= $group_filter . " " . $user_filter . " -print";
#
open(PURGED,"> $Purged_Files_Log") or
    die("###ERROR Could not open file for $Purged_Files_Log.");
#
### $q_find_opt = quotemeta($find_opt); ### OVERKILL! Does too much.
$q_find_opt = $find_opt;
$q_find_opt =~ s/\(/\\\(/g; # Add backslash before open & close paren, and exclamation point.
$q_find_opt =~ s/\)/\\\)/g;
$q_find_opt =~ s/\!/\\\!/g;
$q_find_opt =~ s/\s\s+/ /g; # replace two or more blanks by one
#
printf(LOG    "%s %s\n\n",$find,$find_opt);
printf(PURGED "%s %s\n\n",$find,$find_opt);
#
open(FIND,"$find $q_find_opt |") or
    die("###ERROR Could not open pipe from $find $find_opt");

#
# 1,234,567,890 12,345,678,901,234
#               TB  GB  MB  KB   B
printf(PURGED "Files purged:\n");
# printf(PURGED "                                     Time_Accessed Date_the_file_was_last_accessed Time_Modified Date_the_file_was_last_modifed\n");
# printf(PURGED "Username Group        Filesize Bytes dddd-hh:mm:ss CCYY.MM-Mon.DD-Day_HH:MM:SS-Zon dddd-hh:mm:ss CCYY.MM-Mon.DD-Day_HH:MM:SS-Zon File_path\n");
# printf(PURGED "======== ============ ============== ============= =============================== ============= =============================== ====================\n");
#                12345678 123456789012 12345678901234 12345678(1)23 12345678(1)2345678(2)2345678(3) 12345678(1)23 12345678(1)2345678(2)2345678(3) 12345678(1)2345678(2
#                     %8s         %12s           %14s          %13s                            %31s          %13s                            %31s %s\n",
#                12345678(1)2345678(2)2345678(3)2345678(4)2345678(5)2345678(6)2345678(7)2345678(8)2345678(9)2345678(0)2345678(1)2345678(2)2345678(3)2345678(4)2345678(5
printf(PURGED "                                     Time_Accessed Time_Modified Time_Changed  Accessed   Modified   Changed\n");
printf(PURGED "Username Group        Filesize_Bytes dddd-hh:mm:ss dddd-hh:mm:ss dddd-hh:mm:ss Epoch_Secs Epoch_Secs Epoch_Secs File_path\n");
printf(PURGED "======== ============ ============== ============= ============= ============= ========== ========== ========== ====================\n");
#              12345678 123456789012 12345678901234 12345678(1)23 12345678(1)23 12345678(1)23 1234567890 1234567890 1234567890 12345678(1)2345678(2
#                   %8s         %12s           %14s          %13s          %13s          %13s       %10s       %10s       %10s %s\n",
#                   0           1              2             3             4             5          6          7          8    9
#              12345678(1)2345678(2)2345678(3)2345678(4)2345678(5)2345678(6)2345678(7)2345678(8)2345678(9)2345678(0)2345678(1)2345678(2)2345678(3)2345678(4)2345678(5
#  
#
$files_purged = 0;
$bytes_purged = 0;
$blocksize_purged = 0;
#
while (defined($filename = <FIND>)) {
    chomp($filename);
    @stat = stat($filename);
    next if ($#stat < 0);
    next if (! -f _);
    $a = -A _;
    $c = -C _;
    $m = -M _;
    ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = @stat;
    printf(PURGED "###RAW### %s\n",join(' ',($filename,@stat,$m,$a))) if ($debug > 1);


#
### ### next if (exists($qstat_users{$uid}));
#
#   Filter off directory trees to be avoided.
#
    $avoid_dir_tree = 0;
    foreach $dir_to_avoid (@paths_to_avoid) {
        $path_to_avoid = $Purge_File_System . "/" . $dir_to_avoid ;
        if ($filename =~ m/^${path_to_avoid}/) {
            $avoid_dir_tree = 1;
            last;
        } #end_if
    } #end_foreach $dir_to_avoid
    next if $avoid_dir_tree;

#
# User name subdirectories to avoid anywhere within the user directories.
#
    $avoid_dir_tree = 0;
    foreach $usubdir_to_avoid (@user_subdir_to_avoid) {
        if ($filename =~ m/^$Purge_File_System\/([^\/]*\/)+$usubdir_to_avoid/) {
            $avoid_dir_tree = 1;
            last;
        } #end_if
    } #end_foreach $usubdir_to_avoid
    next if $avoid_dir_tree;

$username = defined($user{$uid})?$user{$uid}:$uid;
$group    = defined($group{$gid})?$group{$gid}:$gid;
#
#                       0     1    2    3    4    5    6  7
#     printf(PURGED "%-8s %-12s %14s %13s %31s %13s %31s %s\n",
#            $username,$group,$size,dddd_hhmmss($a),ts($atime),dddd_hhmmss($m),ts($mtime),$filename);
#             0         1      2                 3      4                   5      6       7
#                  0    1     2    3    4    5    6    7    8    9
    printf(PURGED "%-8s %-12s %14s %13s %13s %13s %10s %10s %10s %s\n",
           $username,$group,$size,dddd_hhmmss($a),dddd_hhmmss($m),dddd_hhmmss($c),$atime,$mtime,$ctime,$filename);
#          0         1      2                 3               4               5   6      7      8      9
#

    if ($EFFECTIVE_USER_ID == 0) {
# this is the debug line, if you want to test this script, uncomment the "FOR TESTING ONLY" line and comment out "PRODUCTION PURGE"
#    	$cnt = 1;                  ####### FOR TESTING ONLY! #######
        $cnt = unlink($filename);  ####### PRODUCTION PURGE  #######
        warn("###ERROR Could not unlink the file $filename.") if ($cnt < 1);
	
### added by Chris and Andrew to send filename to stdout
  ###   printf("$filename\n");

        $files_purged++;
        $bytes_purged += $size;
        $blocksize_purged += $blksize * $blocks;
    } #end_if
} #end_while

### Added by ams and ccirullo
printf("end of while");

#
#               )2345678(1)2345678
# 1,234,567,890 12,345,678,901,234
#               TB  GB  MB  KB   B
#
1 while $files_purged     =~ s/(\d)(\d\d\d)(?!\d)/$1,$2/g;  # perl5 put commas in the right places in an integer
1 while $bytes_purged     =~ s/(\d)(\d\d\d)(?!\d)/$1,$2/g;
if ( $blocksize_purged    =~ m/^\d+$/) {
    1 while $blocksize_purged =~ s/(\d)(\d\d\d)(?!\d)/$1,$2/g; # if too large, 1.4835386844971e+16 becomes 1.4,835,386,844,971e+16
} #end_if
#
printf(LOG "\n");
printf(LOG "# of files purged       = %18s\n",$files_purged);
printf(LOG "# of bytes purged       = %18s\n",$bytes_purged);
printf(LOG "# of block bytes purged = %18s\n",$blocksize_purged );
close(FIND);
close(PURGED);
#
######################################################################################################
#
# [sp017 98] df -P -k /gpfs
# Filesystem    1024-blocks      Used Available Capacity Mounted on
# /dev/lv_gpfs     71024640   8964588  62060052      13% /rmount/gpfs
# 0                1          2        3             4   5
#
@lines=`$df $df_opts`;
#
$child_error = $CHILD_ERROR;
#
$line = $lines[1];
chomp($line);
@pieces = split(' ',$line);
#
if ($child_error || ($#lines > 1) || ($#pieces != 5) || ($debug > 1)) {
    $Exit_Status = ($child_error >> 8) & 0xff;
    $Intr_Status = ($child_error       & 0xff);
    printf(STDERR "###");
    printf(STDERR "ERROR") if ($child_error || ($#lines > 0));
    printf(STDERR " exit=%d intr=%d 0x%04x = %s %s\n",$Exit_Status,$Intr_Status,$child_error,$df,$df_opts);
    for ($i = 0 ; $i <= $#lines ; $i++) {
        printf(STDERR "### %s:%s: %s",$df,$i,$lines[$i]);
    } #end_for $i
    exit($child_error) if ($child_error);
} #end_if
#
$percent_used = $pieces[4]; # 13%
if ($pieces[4] =~ m/^(\d+)\%$/) {
    $percent_used = $1;
} else {
    die("###ERROR Could not parse Capacity(%) in $line");
} #end_if
$percent_free = 100 - $percent_used;
#
printf(LOG "\n");
printf(LOG "/bin/df of %s after disk purge.\n",$Purge_File_System);
printf(LOG "%s",$lines[0]);
printf(LOG "%s\n",$line);
printf(LOG "\n");
printf(LOG "Percent free %d %%\n",$percent_free);
printf(LOG "Percent used %d %%\n",$percent_used);
printf(LOG "\n");
#
######################################################################################################
#
open(LAST,"> $Last_Successful_Purge") or
    die("###ERROR Could not create file $Last_Successful_Purge.");
#
$time = time();
#
$ENV{"TZ"} =  "PST8PDT";
@zone_name = ("PST","PDT");  # Pacific Standard Time / Pacific Daylight savings Time
#
$local_time2 = ts($time); # like `/bin/date "+%Y%m%d_%H%M%S_%Z_%a"`; ### CCYY.MM-Mon.DD-Day_HH:MM:SS-Zon
#
$ENV{"TZ"} =  "CUT0";
@zone_name = ("CUT","GMT"); # Coordinated Universal Time or Greenwich Mean Time (or UTC)
#
$cut_time2 = ts($time);  # Example: 1997.05-May.06-Fri_02:13:06-CUT
#
$delta = ($time - $BASETIME) / 60.0 / 60.0 / 24.0; # in days
#
printf(LAST "Local time started   = %s\n",$local_time);
printf(LAST "Local time completed = %s\n",$local_time2);
printf(LAST "\n");
printf(LAST "CUT   time started   = %s\n",$cut_time);
printf(LAST "CUT   time completed = %s\n",$cut_time2);
printf(LAST "\n");
printf(LAST "Time to complete purge = %s (dddd_HH:MM:SS)\n",dddd_hhmmss($delta));
#
printf(LOG "Local time started   = %s\n",$local_time);
printf(LOG "Local time completed = %s\n",$local_time2);
printf(LOG "\n");
printf(LOG "CUT   time started   = %s\n",$cut_time);
printf(LOG "CUT   time completed = %s\n",$cut_time2);
printf(LOG "\n");
printf(LOG "Time to complete purge = %s (dddd_HH:MM:SS)\n",dddd_hhmmss($delta));
#
close(LAST);
close(LOG);
#
######################################################################################################
#
system("$find $Purge_Log_Directory_Top -type f -exec /bin/chown sjames:users \{\} \\\;");
system("$find $Purge_Log_Directory_Top -type f -exec /bin/chmod u=rw,go=r    \{\} \\\;");
#
exit(0); # end_program main()
#
######################################################################################################
######################################################################################################
######################################################################################################
#
# getopts.pl - a better getopt.pl
# Usage:
#      do Getopts('a:bc');  # Option -a takes argument, options -b & -c do not.
#                           # Sets opt_*, where * is the option letter as a side effect.
#
sub Getopts {
    local($argumentative) = @_;
    local(@args,$_,$first,$rest);
    local($errs) = 0;
    local($[) = 0;

    @args = split( / */, $argumentative );

    while(@ARGV && ($_ = $ARGV[0]) =~ /^-(.)(.*)/) {
        ($first,$rest) = ($1,$2);
        $pos = index($argumentative,$first);
        if($pos >= $[) {
            if (defined($args[$pos+1]) && ($args[$pos+1] eq ':')) {
                shift(@ARGV);
                if($rest eq '') {
                    ++$errs unless @ARGV;
                    $rest = shift(@ARGV);
                } #end_if
                eval "\$opt_$first = \$rest;";
            } else {
                eval "\$opt_$first = 1";
                if($rest eq '') {
                    shift(@ARGV);
                } else {
                    $ARGV[0] = "-$rest";
                } #end_if
            } #end_if
        } else {
            print STDERR "Unknown option: $first\n";
            ++$errs;
            if($rest ne '') {
                $ARGV[0] = "-$rest";
            } else {
                shift(@ARGV);
            } #end_if
        } #end_if
    } #end_while
    $errs == 0;
} #end_sub Getopts
#
##################################################################################################
##################################################################################################
##################################################################################################
#
# This subroutine ts() produces a timestamp of the form:
#     CCYY.MM-Mon.DD-Day_HH:MM:SS-Zon
# ex. 1997.05-May.06-Fri_02:13:06-CUT
#
##################################################################################################
#
sub ts {
    my ($time);
    my ($local_time);
    my ($sec);
    my ($min);
    my ($hour);
    my ($mday);
    my ($month);
    my ($month0);
    my ($year);
    my ($yy);
    my ($wday);
    my ($yday);
    my ($isdst);
    my (@month_name0);
    my (@day_name);
#
#                   0     1     2     3     4     5     6
    @day_name   = ("Sun","Mon","Tue","Wed","Thu","Fri","Sat");
    @month_name0 = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
#                    0     1     2     3     4     5     6     7     8     9     10    11
### @month_name1 = (-1,"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
#                       1     2     3     4     5     6     7     8     9     10    11    12
#
    if ($#_ > -1) {
        $time = $_[0];    # use argument if supplied
    } else {
        $time  = time();  # get time if no argument supplied
    } #end_if
#
    ($sec,$min,$hour,$mday,$month0,$yy,$wday,$yday,$isdst) = localtime($time);
### ($sec,$min,$hour,$mday,$month0,$yy,$wday,$yday,$isdst) = gmtime(time);
    $month = $month0 + 1;
    $year  = $yy + 1900;
#
#                          CCYY.  MM-Mon.  DD-Day_  HH:  MM:  SS-Zon
    $local_time = sprintf("%04d.%02d-%3s.%02d-%3s_%02d:%02d:%02d-%3s",
                         $year,$month,$month_name0[$month0],$mday,$day_name[$wday],
                          $hour,$min,$sec,$main::zone_name[$isdst]);
#
    return($local_time);
} #end_sub ts
#
##################################################################################################
##################################################################################################
##################################################################################################
#
sub ppid {
#   c90-128> /bin/ps -o pid,ppid
#       PID   PPID
#     17266  17241
#     11723  17266
#         0      1
#
#   NOTE: DOES NOT WORK FOR CRON JOBS.  PS RETURNS ERROR.
#
    my ($child_error);
    my ($debug);
    my ($Exit_Status);
    my ($i);
    my ($Intr_Status);
    my (@lines);
    my (@pieces);
    my ($ps);
    my ($ps_opts);
#
    if (defined($main::ps)) {
        $ps = $main::ps;
    } else {
        $ps = "/bin/ps";
    } #end_if
#
    $ps_opts = "-o pid,ppid";
#
    if (defined($main::debug)) {
        $debug = $main::debug;
    } else {
        $debug = 0;                               ### default debug level (0=off)
    } #end_if
#
    if (-x "$ps") {
        @lines = `$ps $ps_opts`;
        $child_error = $CHILD_ERROR;
#
        chomp(@lines);
#
        if ($child_error || ($#lines < 0) || ($debug > 1)) {
            $Exit_Status = ($child_error >> 8) & 0xff;
            $Intr_Status = ($child_error       & 0xff);
            printf(STDERR "\#\#\#");
            printf(STDERR "ERROR") if ($child_error || ($#lines < 0));
            printf(STDERR " exit=%d intr=%d 0x%04x = %s %s\n",$Exit_Status,$Intr_Status,$child_error,$ps,$ps_opts);
            for ($i = 0 ; $i <= $#lines ; $i++) {
                printf(STDERR "\#\#\# %s:%s: %s\n",$ps,$i,$lines[$i]);
            } #end_for $i
            return(-$child_error) if ($child_error || ($#lines < 0));
        } #end_if
#
        for ($i = 1 ; $i <= $#lines ; $i++) { # skip "  PID   PPID" heading
            @pieces = split(' ',$lines[$i]);
            if ($#pieces == 1) {
                if ($pieces[0] == $PROCESS_ID) {
                    return( ($pieces[1]) );
                } #end_if
            } #end_if
        } #end_for $i
    } else {
        return(undef);
    } #end_if
    return(undef);
} #end_sub ppid
#
##################################################################################################
##################################################################################################
##################################################################################################
#
sub dddd_hhmmss {
    my $time;
    my $seconds;
    my $minutes;
    my $hours;
    my $days;
    my $hhmmss;
#
    if ($#_ < 0) {
        return("-1:-1:-1");
    } elsif (!defined($_[0])) {
        return("-2:-2:-2");
    } #end_if
#
    $time    = $_[0];                   # floating point time in days
#
    $days    = int($time);              # integer days
    $time    = ($time - $days) * 24;    # floating point hours
#
    $hours   = int($time);
    $time    = ($time - $hours) * 60;   # to minutes
#
    $minutes = int($time);
    $time    = ($time - $minutes) * 60; # to seconds
#
    $seconds = int($time);
    $time    = $time - $seconds;        # fraction
#
### if ( ($days == 0) && ($hours == 0) && ($minutes == 0) ) {
###     $hhmmss = sprintf("%2d",$seconds);
### } elsif ( ($days == 0) && ($hours == 0) ) {
###     $hhmmss = sprintf("%2d:%02d",$minutes,$seconds);
### } elsif ($days == 0) {
###     $hhmmss = sprintf("%2d:%02d:%02d",$hours,$minutes,$seconds);
### } else {
#       $hhmmss = sprintf("%4d-%02d:%02d:%02d",$days,$hours,$minutes,$seconds);
        $hhmmss = sprintf("%d-%02d:%02d:%02d",$days,$hours,$minutes,$seconds);
### } #end_if
#
    return ($hhmmss);
} #end_sub dddd_hhmmss
#
##################################################################################################
##################################################################################################
##################################################################################################
#
