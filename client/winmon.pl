use v5.10;
use strict;
use warnings;
use Data::Dumper;
use Getopt::Std;
use Sys::Hostname;
use Socket;
use Carp;
use Win32;
use FindBin;
use lib "$FindBin::Bin/..";
use Monitor::Windows;

getopts("i:m:u:p:");

our ($opt_i,$opt_m,$opt_u,$opt_p);
my $MSIZE = 1024 * 1024;

my $rephash = {};
my $address = inet_ntoa((gethostbyname(hostname))[4]);
my $report;
unless($opt_i){
    &ShowHelp();
    exit;
}

sub ShowHelp{
    my $usage =<< "__HELP_END";
Usage:
      wmon -i monitor interval(seconds)
	   -m monitor windows computer IP
	   -u windows computer username
	   -p windows computer password
__HELP_END
    print $usage,"\n";
}
my $compip = "";
if(defined $opt_m){
    $compip = $opt_m;
}else{
    $compip = "127.0.0.1";
}

my $wmi = Monitor::Windows->new(
    computerIP => $compip,
    username => $opt_u,
    password => $opt_p,
    );

my $OS_String = $wmi->GetOs();

if($compip eq "127.0.0.1"){
    $rephash->{server_ip} = $address;
}else{
    $rephash->{server_ip} = $compip;
}


$rephash->{server_status} = "";
$rephash->{server_time} = "";
$rephash->{server_os} = $OS_String;
$opt_i = 5 unless $opt_i;

my $pmem_mb = 0;
my $cnt = 0;

my $pmem_total = $wmi->GetPhyMem();
$pmem_mb = $pmem_total / $MSIZE;


while(1){
    my $index = "Win32_Processor";
    my $cpu = int($wmi->GetCpuLoad());
    $index = "Win32_PerfRawData_PerfOS_Memory";
    my $amem = $wmi->GetFreeMem();
    my $mem = int( 100 * ($pmem_mb - $amem) / $pmem_mb);
    
    $rephash->{server_cpu} = sprintf("%.2f",$cpu);	    
    $rephash->{server_mem} = sprintf("%.2f",$mem);	    
    my($date,$time) = &GetLocalTime('-');
    $rephash->{server_time} = sprintf("%s %s",$date,$time);
    $rephash->{server_hdp} = $wmi->GetDiskUsage();	    
    say $date . " " . $time . " " . "\tCPU Usage: " .$cpu. "%\tPhysical Memory: " . $mem . "%" . " disk: " . $rephash->{server_hdp} . "%";    
    sleep($opt_i);
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
