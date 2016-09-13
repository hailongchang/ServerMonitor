#! /usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use Socket;
use Net::Address::IP::Local;
use FindBin;
use lib "$FindBin::Bin/..";
use Monitor::Linux;

our $opt_i;
getopts("i:n:");

my $k = 1024;
my $m = 1024 * 1024;
my $g = 1024 * 1024 * 1024;


my $rephash = {};
my $address = Net::Address::IP::Local->public;

unless($opt_i){
    &ShowHelp();
    exit;
}

sub ShowHelp{
    my $usage =<< "__HELP_END";
Usage:
    linuxmon -i monitor interval(seconds)
__HELP_END
    print $usage,"\n";
}

$rephash->{server_ip} = $address;
$rephash->{server_time} = "";
$rephash->{server_os} = osdesp();
$rephash->{server_hdp} = dusage();
$opt_i = 5 unless $opt_i;

my ($t1,$t2,$k1,$k2,$cpu,$mem);

while(1){
    ($t2,$k2) = syscpu();
    if($t1 and $k1){
	my $total = $t2 - $t1;
	my $tidle = $k2 - $k1;
	$cpu = sprintf("%.2f",100 * ($total - $tidle) / $total);
	$mem = sysmem();
	$rephash->{server_cpu} = $cpu;
	$rephash->{server_mem} = $mem;
	my($date,$time) = &GetLocalTime('-');		
	$rephash->{server_time} = sprintf("%s %s",$date,$time);
	$rephash->{server_hdp} = dusage();
	&printstatus()
    }

    $t1 = $t2;
    $k1 = $k2;
    sleep($opt_i);
}


sub printstatus{
    printf("%s\tip=%s\ttime=%s\tsys_cpu=%s%%\tsys_mem=%s%%\tserver_hdp=%s%%\n",
	   $rephash->{server_os},
	   $rephash->{server_ip},
	   $rephash->{server_time},
	   $rephash->{server_cpu},
	   $rephash->{server_mem},
	   $rephash->{server_hdp},
	);    
    print"--------------------------------------------------------------------\n";
}

sub GetLocalTime{    
    my($delimiter) = @_;

    $delimiter = '' unless defined $delimiter;
    my($sec,$min,$hour,$mday,$mon,$year,undef,undef,undef) = localtime(time);

    return(
	($year + 1900) . $delimiter . 
	(((++$mon) < 10) ? ("0" . $mon) : ($mon)) . $delimiter . 
	((($mday) < 10 ) ? ("0" . $mday) : ($mday)),

	((($hour) < 10 ) ? ("0" . $hour) : ($hour)) . ":" . 
	((($min) < 10 ) ? ("0" . $min) : ($min)) . ":" .
	((($sec) < 10 ) ? ("0" . $sec) : ($sec))
	);
}
