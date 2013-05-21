# Copyrights 2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package Google::Merchant;
use vars '$VERSION';
$VERSION = '0.13';


use Log::Report 'google-merchant';

use XML::Compile::Cache    ();
use XML::LibXML            ();
use Google::Merchant::Util qw/:ns10/;
use Scalar::Util           qw/blessed/;
use Encode                 qw/encode/;

my $schemas;


sub new($%) { my $class = shift; (bless {}, $class)->init( {@_} ) }

sub init($)
{   my ($self, $args) = @_;

    unless($schemas)
    {   $schemas = $self->_loadSchemas;
        $schemas->compileAll;
    }

    $self->{GM_feed}        = {};
    $self->{GM_string_format} = $args->{string_format} || 'HTML';
    $self;
}

sub _loadSchemas()
{   my $self = shift;

    $schemas = XML::Compile::Cache->new
      ( # prefixes must be kept short, to reduce transported file size
        prefixes    => [g => NS_GOOGLE_BASE10, c => NS_GOOGLE_CUSTOM10]
      , any_element => 'TAKE_ALL'
      );
    $self->_loadXSD($schemas, 'google-base-10.xsd')
         ->_loadXSD($schemas, 'google-base-10-bug.xsd');

    $schemas->declare(WRITER => 'g:item', hooks =>
      [ { type    => 'g:stringAttrValueType'
        , replace => sub {$self->_write_string(@_)} }
      ] );

    $schemas;
}

sub _loadXSD($)
{   my ($self, $schemas, $schema_fn) = @_;
    (my $fn = __FILE__) =~ s!([/\\])(\w+)\.pm$!$1$2$1xsd$1$schema_fn!;
    $schemas->importDefinitions($fn);
    $self;
}

#---------

sub feed()    {shift->{GM_feed}}
sub schemas() {$schemas}

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
    $args{feed}   = $self->feed;
    $self->_write($fn, \%args);
}

sub _write($$) { panic "not implemented" }

sub _write_base_entry($$)
{   my ($self, $doc, $base) = @_;
    $self->schemas->writer('g:item')->($doc, $base);
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

    my $str = encode 'utf8', $val;
    $str = XML::LibXML::CDATASection->new($str)
        if $type ne 'TEXT' && $str =~ m/\&/;

    $r->($doc, $str);
}

#------------

1;
