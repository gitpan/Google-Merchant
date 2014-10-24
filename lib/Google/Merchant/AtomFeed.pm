# Copyrights 2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package Google::Merchant::AtomFeed;
use vars '$VERSION';
$VERSION = '0.14';

use base 'Google::Merchant';

use Log::Report 'google-merchant';

use Google::Merchant::Util qw/:ns10/;
use XML::Compile::Util     qw/XMLNS/;
use Encode                 qw/encode/;


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    my $title  = $args->{title}   || panic "feed title required";
    my $site   = $args->{website} || panic "feed website required";

    # Google only supports these three, it seems
    my @globs;
    push @globs, +{title   => $title};
    push @globs, +{link    => +{rel => 'self', href => $site}};
    push @globs, +{updated => ($args->{updated} || time) };

    {  no strict;  # in devel, $VERSION undeclared
       push @globs, +{generator => __PACKAGE__ . ' '. ($VERSION || 'undef')}
    }
    push @globs, +{entry => ($self->{GMA_entries} = []) };

    my $feed = $self->feed;
    $feed->{cho_author} = \@globs;
    $feed->{base} = $args->{base} || $site;
    $feed->{lang} = $args->{language};

    $self;
}

sub _loadSchemas()
{   my $self = shift;
    my $schemas = $self->SUPER::_loadSchemas();

    $schemas->prefixes('' => NS_ATOM_2005);
    $self->_loadXSD($schemas, 'atom-2005.xsd');
    $schemas->importDefinitions(XMLNS);
    $schemas->declare
      ( WRITER => 'feed'
      , mixed_elements => 'STRUCTURAL'
      , hook   =>
         [ +{ type    => 'textType'
            , replace => sub {$self->_write_texttype(@_) }
            }
         , +{ type    => 'entryType'
            , replace => sub {$self->_write_entrytype(@_)}
            }
         ]
      );

    $schemas;
}

#---------

sub addItem(%)
{   my ($self, %args) = @_;

    my $title = delete $args{title}       or panic "entry title required";
    my $page  = delete $args{webpage}     or panic "entry webpage required";
    my $descr = delete $args{description};

    my @glob;
    push @glob, +{title  => $title};
    push @glob, +{link   => +{href => $page}};
    push @glob, +{summary => $descr};
    my $entry = +{cho_author => \@glob, _base => $self->_baseItem(\%args)};

    push @{$self->{GMA_entries}}, $entry;
    $entry;
}

#----------------

sub _write($$)
{   my ($self, $fn, $args) = @_;
    my $format = $args->{beautify} || 0;
    my $doc    = $args->{doc};

    my $root   = $self->schemas->writer('feed')->($doc, $args->{feed});
    $root->setNamespace(NS_GOOGLE_BASE10,   'g', 0);
    $root->setNamespace(NS_GOOGLE_CUSTOM10, 'c', 0);
    $doc->setDocumentElement($root);
    $doc->setCompression($args->{gzip}) if defined $args->{gzip};
    $doc->toFile($fn, $format);
    $self;
}

# Hook, because textType is mixed!
sub _write_texttype($$$$$)
{   my ($self, $doc, $val, $path, $tag, $r) = @_;
    my ($text, %attr);
    if(ref $val eq 'HASH')
    {   %attr = %$val;
        $text = delete $attr{_};
    }
    else
    {   $text = $val;
    }

    # Clean to use 'type' in atom elements, however the google server
    # confuses this  with its own "type" attributes.
#   $attr{type} ||= lc $self->stringFormat;

    my $xml  = $r->($doc, \%attr);
    $xml->appendText(encode 'utf8', $text);
    $xml;
}

sub _write_entrytype($$$$$)
{   my ($self, $doc, $val, $path, $tag, $r) = @_;
    my $base  = $self->_write_base_entry($doc, delete $val->{_base});
    my $node  = $r->($doc, $val);
    $node->appendChild($_) for $base->childNodes;

    # The xmlns:g is lost here, added globally
    $node;
}

1;
