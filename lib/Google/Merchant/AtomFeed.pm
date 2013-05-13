# Copyrights 2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package Google::Merchant::AtomFeed;
use vars '$VERSION';
$VERSION = '0.11';

use base 'Google::Merchant';

use Log::Report 'google-merchant';

use XML::Compile::Util qw/XMLNS/;


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

    $schemas->prefixes(a => 'http://www.w3.org/2005/Atom');
    $self->_loadXSD($schemas, 'atom-2005.xsd');
    $schemas->importDefinitions(XMLNS);
    $schemas->declare
      ( WRITER => 'a:feed'
      , mixed_elements => 'STRUCTURAL'
      , hook   =>
         [ +{ type    => 'a:textType'
            , replace => sub {$self->_write_texttype(@_) }
            }
         , +{ type    => 'a:entryType'
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
    my $descr = delete $args{description} or panic "entry descriptions required";
    my $page  = delete $args{webpage}     or panic "entry webpage required";

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

    my $root   = $self->schemas->writer('a:feed')->($doc, $args->{feed});
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
    $attr{type} ||= lc $self->stringFormat;

    my $xml  = $r->($doc, \%attr);
    $xml->appendText($text);
    $xml;
}

sub _write_entrytype($$$$$)
{   my ($self, $doc, $val, $path, $tag, $r) = @_;
    my $base  = $self->_write_base_entry($doc, delete $val->{_base});
    my $node  = $r->($doc, $val);
    $node->appendChild($_) for $base->childNodes;
    $node;
}

1;
