# Copyrights 2013-2014 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package Google::Merchant::Util;
use vars '$VERSION';
$VERSION = '0.15';

use base 'Exporter';

use Log::Report 'google-merchant';

my @ns10    = qw/NS_GOOGLE_BASE10 NS_GOOGLE_CUSTOM10 NS_ATOM_2005/;

our @EXPORT = (@ns10);

our %EXPORT_TAGS =
  ( ns10 => \@ns10
  );


use constant
 { NS_GOOGLE_BASE10   => 'http://base.google.com/ns/1.0'
 , NS_GOOGLE_CUSTOM10 => 'http://base.google.com/cns/1.0'
 , NS_ATOM_2005       => 'http://www.w3.org/2005/Atom'
 };
