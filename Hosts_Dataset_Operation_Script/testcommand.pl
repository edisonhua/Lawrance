use strict;
use warnings;

use Data::Dumper;   # $fields[3] => Month $fields[0] => user $fields[8] => Time

my $user_time = {};
my $time = {};
open my $READ , '<', 'test' or die;

while(my $line = <$READ>){
    my @fields = split(' ', $line);

    my $user = $fields[0];
    my $month = $fields[3];

    $fields[8] =~ m/([\d]*)\+?([\d]{2}):([\d]{2})/; #time format
    my $min = $3;
    my $hr = $2;
    my $day = $1;
    $day = 0 if (!$day);
    if (!exists $user_time->{$month}->{$user}){
        $time = {};
    }
    $time->{'day'} += $day*24;
    $time->{'hr'} += $hr;
    $time->{'min'} += $min;

    $user_time->{$month}->{$user} = $time;
}
close $READ;
foreach my $month (keys %$user_time){
    print "[$month]\n";
    my $user_hash = $user_time->{$month};
    foreach my $user (keys %$user_hash){
        my $time = $user_hash->{$user};
        print "$user\t". $time->{'day'}.'.'.$time->{'hr'}.'.'.$time->{'min'}."hours\n";
    }
}