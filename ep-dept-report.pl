#!/usr/bin/perl -I/eprints/eprints3/perl_lib

use strict;
use warnings;
use Data::Dumper;

open DEPTREPORT,  ">dept-report.csv" or die " can't open report file dept-report.csv: $!";
print DEPTREPORT "Department Name, Number of Staff, Total Items, Items with ID over 2M, Public Docs, Private Docs\n";

my $date_value = '-2014-06-31'; #all dates up to June 31st 2014
use EPrints;
binmode(STDOUT, ':utf8');

my $repositoryid = $ARGV[0];
die "USAGE: report.pl *repositoryid* \n" unless $repositoryid ;

my $ep = EPrints->new();
my $repo = $ep->repository( $repositoryid );
my $deptid;

die "Could not create repository object for $repositoryid\n" unless $repositoryid;

my $sql = 'select distinct DEPT from "USER"';
        my $sth = $repo->get_database->prepare( $sql );
        $sth->execute;

        while(my @row = $sth->fetchrow_array)
        {
                $deptid = @row[0];
                print "Department: $deptid\n";

my $us = $repo->dataset('user');
my $usearch = $us->prepare_search();

$usearch->add_field($us->field('dept'), $deptid);

my $ulist = $usearch->perform_search;
my $ids = $ulist->ids;
#print Dumper $ids;
print $ulist->count." members of staff\n";
my $ds = $repo->dataset('archive');

my $counts = {};
foreach my $id (@$ids){
my $search = $ds->prepare_search();
#print $id." . ";
$search->add_field($ds->field('eprint_status'), 'archive');
$search->add_field($ds->field('userid'), $id);
my $list = $search->perform_search;


$list->map( sub
{
        my ($repo, $ds, $dataobj, $counts) = @_;

        my @docs = $dataobj->get_all_documents;
        my $public = 0;
        my $private = 0;
        foreach my $doc (@docs)
        {
                if ($doc->value('security') eq 'public')
                {
                        $public++;
                }
                else
                {
                        $private++;
                }
        }

        if ($public)
        {
                $counts->{public}++;
        }
        elsif ($private)
        {
                $counts->{private}++;
        }
        if ($dataobj->get_value("eprintid") >2000000) {$counts->{new}++;}
        $counts->{total}++;

}, $counts);
}
print Dumper $counts;
if ($counts->{total}){print DEPTREPORT "\""$deptid."\" , ".$usearch->count." , ".$counts->{total}." , ".$counts->{new}." , ".$counts->{public}." , ".$counts->{private}."\n";}
}
close DEPTREPORT;
