#!/usr/bin/env perl
# Check custom extensions

use warnings;
use strict;

use lib qw/lib t/;
use Test::More tests => 1;

use XML::Compile::Tester        'compare_xml';

use Google::Merchant::Util      ':ns10';
use Google::Merchant::AtomFeed  ();

my $feed = Google::Merchant::AtomFeed->new
  ( title   => 'Demo Webshop'
  , website => 'https://webshop.example.com'
  , updated => 1368314089  # defaults to time()
  );

my $doc    = XML::LibXML::Document->new('1.0', 'UTF-8');
my $profit = $doc->createElementNS(NS_GOOGLE_CUSTOM10, 'profit');
$profit->appendText('10.53 EUR');
$profit->setAttribute(elementType => 'floatUnit');

$feed->addItem
  ( title   => 'LG Flatron M2262D 22" Full HD LCD TV'
  , webpage => 'http://www.example.com/electronics/tv/LGM2262D.html'
  , description => 'Attractively styled'
  , id      => 'TV_123456'
  , 'c:profit' => $profit
  );

my $tmp = 'custom.xml';
$feed->write($tmp, beautify => 1, doc => $doc);

open XML, '<:encoding(utf8)', $tmp or die $!;
my $xml = join '', <XML>;
close XML;

my $version = $Google::Merchant::AtomFeed::VERSION || 'undef';
compare_xml $xml, <<__XML;
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom"
    xmlns:g="http://base.google.com/ns/1.0"
    xmlns:c="http://base.google.com/cns/1.0" 
    base="https://webshop.example.com">
  <title>Demo Webshop</title>
  <link href="https://webshop.example.com" rel="self"/>
  <updated>2013-05-11T23:14:49Z</updated>
  <generator>Google::Merchant::AtomFeed $version</generator>
  <entry>
    <title>LG Flatron M2262D 22" Full HD LCD TV</title>
    <link href="http://www.example.com/electronics/tv/LGM2262D.html"/>
    <summary>Attractively styled</summary>
    <g:id>TV_123456</g:id>
    <profit xmlns="http://base.google.com/cns/1.0" elementType="floatUnit">10.53 EUR</profit>
  </entry>
</feed>
__XML
