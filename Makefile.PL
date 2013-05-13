use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'Google::Merchant'
 , VERSION	=> '0.11'
 , PREREQ_PM    =>
   { XML::Compile::Cache       => 0.994
   , XML::Compile              => 1.34
   , XML::Compile::Tester      => 0
   , Log::Report               => 0.19
   , Test::More                => 0.54
   }

 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'Google Merchant interface'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
EXTENDS		= ../XMLCompile:../XMLCache
RAWDIR          = ../public_html/google-merchant/raw
DISTDIR         = ../public_html/google-merchant/source
LICENSE         = artistic
SKIP_LINKS	= XML::LibXML

# for POD
FIRST_YEAR      = 2013
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/xml-compile/
PODTAIL		= ../XML-shared-podtail
__POSTAMBLE
