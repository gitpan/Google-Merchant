# Copyrights 2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package Google::Merchant;
use vars '$VERSION';
$VERSION = '0.10';

use base 'XML::Compile::Cache';

use Log::Report 'google-merchant';

use Google::Merchant::Util ':ns10';
use Scalar::Util           'blessed';
use XML::LibXML            ();


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    # prefixes must be kept short, to reduce transported file size
    $self->prefixes(g => NS_GOOGLE_BASE10, c => NS_GOOGLE_CUSTOM10);
    $self->_loadXSD('google-base-10.xsd');
    $self->_loadXSD('google-base-10-bug.xsd');

    $self->declare(WRITER => 'g:item', hooks =>
      [ { type    => 'g:stringAttrValueType'
        , replace => sub {$self->_write_string(@_)} }
      ] );

    $self->{GM_feed}        = {};
    $self->{GM_string_format} = $args->{string_format} || 'HTML';

    $self;
}

sub _loadXSD($)
{   my ($self, $schema_fn) = @_;
    (my $fn = __FILE__) =~ s!([/\\])(\w+)\.pm$!$1$2$1xsd$1$schema_fn!;
    $self->importDefinitions($fn);
    $self;
}

sub _feed() { shift->{GM_feed} }

#---------

sub stringFormat() { shift->{GM_string_format} }


sub addItem() {panic "not implemented"}

sub _baseItem($)
{   my ($self, $google) = @_;
    
    # more smart behavior may be required for the google base params
    $google;
}

#----------------

sub write($%)
{   my ($self, $fn, %args) = @_;
    $args{doc}  ||= XML::LibXML::Document->new('1.0', 'UTF-8');
    $args{feed}   = $self->_feed;
    $self->_write($fn, \%args);
}

sub _write($$) { panic "not implemented" }

sub _write_base_entry($$)
{   my ($self, $doc, $base) = @_;
    $self->writer('g:item')->($doc, $base);
}

sub _write_string($$$$$)
{   my ($self, $doc, $val, $path, $tag, $r) = @_;
    return $val if blessed $val && $val->isa('XML::LibXML::Element');

    my $type;
    if(ref $val eq 'HASH')
    {   $type = $val->{type};
        $val  = $val->{_};
    }
    else
    {   $type = $self->stringFormat;
    }

    $val = XML::LibXML::CDATASection->new($val)
        if $type ne 'TEXT' && $val =~ m/\&/;

    $r->($doc, $val);
}

#------------

1;
