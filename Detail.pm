package WWW::DHL::Detail;
use strict;
#use warnings;
use Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/dhlcheck/;
our $VERSION = '0.3';
use LWP::Simple;

sub dhlcheck {
	my $paketnummer = shift;
	my $language = shift || 'de';

	my @newdata;
	my $data = get("http://nolp.dhl.de/nextt-online-public/set_identcodes.do?lang=$language&idc=$paketnummer");
	$data =~ s/[\n\r]//g;

	my($detail) = ($data =~ /<table border="0" cellspacing="0" class="full eventList">.*<tbody>(.*?)<\/tbody>/);
	while($detail =~ /<tr>(.*?)<\/tr>/ig){
		my $detailone = $1;
		#my($datum) = ($detailone =~ /<td class="event_date">\s*(.*?)\s*(?:h|Uhr)\s*<\/td>/);#old from 0.1
		my($datum) = ($detailone =~ /<td class="event_date">\s*.*?([^<>]+?)\s*(?:h|Uhr).*?\s*<\/td>/);#new in 0.2

		my($ort) = ($detailone =~ /<td class="location">.*?<div class="overflow">\s*(.*?)\s*<\/div>.*?<\/td>/);
		my($daten) = ($detailone =~ /<td class="status lasttd">.*?<div class="overflow">\s*(.*?)\s*<\/div>.*?<\/td>/);
		my %details;
		$details{'datum'} = $datum;
		$details{'ort'} = $ort;
		$details{'daten'} = $daten;
		push(@newdata,\%details)
	}
	my($Sendungsnummer) = ($data =~ /<div id="multicolliPieceCode">\s*(?:Sendungsnummer|Shipment number)\s*(.*?)\s*<\/div>/);
	my($last) = ($data =~ /<tr class="lastStatus">(.*?)<\/tr>/);
	my($lastChange) = ($last =~ /<td>\s*(?:Status from|Status vom) (.*?) (?:h|Uhr)\s*<\/td>/);
	my($lastStatus) = ($last =~ /<div class="statusZugestellt">(.*?)<\/div>/);
	unless($lastStatus){
		$last =~ s/<td>(.*?)<\/td>//;
		($lastStatus) = ($last =~ /<td>\s*(.*?)\s*<\/td>/);
	}

	my $peopleto1 = "";
	my $peopleto2 = "";
	my($lastdata) = ($data =~ /<tr><td class="explorer">&nbsp;<\/td>(.*?)<tr class="lastStatus">/);
	($peopleto1) = ($lastdata =~ /<td>\s*[^<]*\s*<\/td>\s*<td>\s*(.*?)\s*<\/td>/);
	($peopleto2) = ($lastdata =~ /<tr><td class="explorer">&nbsp;<\/td>.*?<td>\s*[^<]*\s*<\/td>\s*<td>\s*(.*?)\s*<\/td>/);
	$peopleto1 =~ s/\s\s*/ /g if($peopleto1);
	$peopleto2 =~ s/\s\s*/ /g if($peopleto2);
	my($Statusyet1) = ($data =~ /<div class="(?:greyprogressbar|greenprogressbar)" style="[^"]*">(.*?)<\/div>/s);
	my($Statusyet) = ($Statusyet1 =~ /<span>(.*?)\%<\/span>/s);

	my %statusyetm = (
		de => {
			0 => 'Kein Status',
			20 => 'Filiale / Sendung an DHL übergeben',
			40 => 'Transport zum Paketzentrum',
			60 => 'Bearbeitung in Paketzentrum',
			80 => 'Zustellung',
			100 => 'Sendung wurde erfolgreich zugestellt'
		},
		en => {
			0 => 'No status',
			20 => 'Post Office / Shipment handed over to DHL',
			40 => 'Transport',
			60 => 'Processing in parcel sorting hub',
			80 => 'Delivery',
			100 => 'Shipment has been delivered successfully'
		}
	);
	$Statusyet = 0 unless($Statusyet);

	return(\@newdata,({
		'shipnumber' => $Sendungsnummer,
		'lastchange' => $lastChange,
		'laststatus' => $lastStatus,
		'status' => $Statusyet,
		'to' => $peopleto1,
		'from' => $peopleto2,
		'statustext' => $statusyetm{$language}{$Statusyet},
		})
	);
}


=pod

=head1 NAME

WWW::DHL::Detail - Perl module for the DHL online tracking service with details.

=head1 SYNOPSIS

	use WWW::DHL::Detail;
	my($newdata,$other) = dhlcheck('paketnumber','de');#de or en for text in german or english

	foreach my $key (keys %$other){# shipnumber, lastchange, laststatus, status, to, from, statustext
		print $key . ": " . ${$other}{$key} . "\n";
	}
	print "\nDetails:\n";

	foreach my $key (@{$newdata}){
		#foreach my $key2 (keys %{$key}){#datum, ort, daten
		#	print ${$key}{$key2};
		#	print "\t";
		#}

		print ${$key}{datum};
		print "\t";
		print ${$key}{ort};
		print "\t";
		print ${$key}{daten};
		print "\n";
	}


=head1 DESCRIPTION

WWW::DHL::Detail - Perl module for the DHL online tracking service with details.

=head1 AUTHOR

    -

=head1 COPYRIGHT

	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO



=cut
