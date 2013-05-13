#!/usr/bin/env perl

use warnings;
use strict;

use lib qw/lib t/;
use Test::More tests => 2;
use XML::Compile::Tester 'compare_xml';

use_ok('Google::Merchant::AtomFeed');

my $feed = Google::Merchant::AtomFeed->new
  ( title   => 'Demo Webshop'
  , website => 'https://webshop.example.com'
  , updated => 1368314089  # defaults to time()
  );

#print $feed->template(PERL => 'a:feed');
#print $feed->template(PERL => 'g:item');

# try to reproduce example
$feed->addItem
  ( title   => 'LG Flatron M2262D 22" Full HD LCD TV'
  , webpage => 'http://www.example.com/electronics/tv/LGM2262D.html'
  , description => 'Attractively styled'
  , id      => 'TV_123456'

  , brand   => '&gt;&quot;&lt'
  , isbn    => { type => 'TEXT', _ => '<">' }
  );

my $tmp = 'atom.xml';
$feed->write($tmp, beautify => 1);

open XML, '<:encoding(utf8)', $tmp or die $!;
my $xml = join '', <XML>;
close XML;

my $version = $Google::Merchant::AtomFeed::VERSION || 'undef';
compare_xml $xml, <<__XML;
<?xml version="1.0" encoding="UTF-8"?>
<a:feed xmlns:a="http://www.w3.org/2005/Atom" base="https://webshop.example.com">
  <a:title type="html">Demo Webshop</a:title>
  <a:link href="https://webshop.example.com" rel="self"/>
  <a:updated>2013-05-11T23:14:49Z</a:updated>
  <a:generator>Google::Merchant::AtomFeed $version</a:generator>
  <a:entry>
    <a:title type="html">LG Flatron M2262D 22" Full HD LCD TV</a:title>
    <a:link href="http://www.example.com/electronics/tv/LGM2262D.html"/>
    <a:summary type="html">Attractively styled</a:summary>
    <g:id>TV_123456</g:id>
    <g:brand><![CDATA[&gt;&quot;&lt]]></g:brand>
    <g:isbn>&lt;"&gt;</g:isbn>
  </a:entry>
</a:feed>
__XML
