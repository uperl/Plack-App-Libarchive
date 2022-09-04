package Plack::App::Libarchive;

use strict;
use warnings;
use 5.020;
use parent qw( Plack::Component );
use experimental qw( signatures postderef );
use Plack::MIME;
use Plack::Util::Accessor qw( archive );
use Path::Tiny qw( path );
use Archive::Libarchive qw( ARCHIVE_WARN ARCHIVE_EOF );

# ABSTRACT: Serve an archive via libarchive as a PSGI web app
# VERSION

=head1 SYNOPSIS

 use Plack::App::Libarchive;
 my $app = Plack::App::Libarchive->new( archive => 'foo.tar.tz' )->to_app;

=head1 DESCRIPTION

This L<PSGI> application serves the content of an archive (any format supported
by C<libarchive> via L<Archive::Libarchive>).  A request to the root for the
app will return an index of the files contained within the archive.

=head1 CONFIGURATION

=over 4

=item archive

The relative or absolute path to the archive.

=back

=head1 SEE ALSO

=over 4

=item L<Archive::Libarchive>

=item L<Plack>

=item L<PSGI>

=back

=cut

sub prepare_app ($self)
{
  my $path = path($self->archive);
  $self->{data}  = $path->slurp_raw;
  $self->{title} = $path->basename;
}

sub call ($self, $env)
{
  my $path = $env->{PATH_INFO} || '/';
  return $self->return_400 if $path =~ /\0/;
  return $self->return_index($env) if $path eq '/';
  return $self->return_entry($path);
}

sub return_entry ($self, $path)
{
  $path =~ s{^/}{};

  my $ar = Archive::Libarchive::ArchiveRead->new;
  $ar->support_filter_all;
  $ar->support_format_all;

  my $ret = $ar->open_memory(\$self->{data});
  if($ret == ARCHIVE_WARN)
  {
    warn $ar->error_string;
  }
  elsif($ret < ARCHIVE_WARN)
  {
    warn $ar->error_string;
    return $self->return_500;
  }

  my $e = Archive::Libarchive::Entry->new;
  while(1)
  {
    my $ret = $ar->next_header($e);
    if($ret == ARCHIVE_EOF)
    {
      last;
    }
    elsif($ret == ARCHIVE_WARN)
    {
      warn $ar->error_string;
    }
    elsif($ret < ARCHIVE_WARN)
    {
      warn $ar->error_string;
      return $self->return_500;
    }

    if($e->pathname eq $path)
    {
      my $res = [ 200, [ 'Content-Type' => Plack::MIME->mime_type($path) ], [ '' ] ];

      if($e->size > 0)
      {
        while(1)
        {
          my $buffer;
          my $ret = $ar->read_data(\$buffer);
          last if $ret == 0;
          if($ret == ARCHIVE_WARN)
          {
            warn $ar->error_string;
          }
          elsif($ret < ARCHIVE_WARN)
          {
            warn $ar->error_string;
            return $self->return_500;
          }
          $res->[2]->[0] .= $buffer;
        }
      }

      push $res->[1]->@*, 'Content-Length' => length($res->[2]->[0]);

      return $res;
    }
    $ar->read_data_skip;
  }

  return $self->return_404;
}

sub return_index ($self, $env)
{
  if($env->{PATH_INFO} eq '') {
    my $url = $env->{REQUEST_URI};
    $url =~ s/\/*$/\//;
    if($url ne $env->{REQUEST_URI})
    {
      return
        [ 301,
          [
            'Location'       => $url,
            'Content-Type'   => 'text/plain',
            'Content-Length' => 8,
          ],
          [ 'Redirect' ],
        ];
    }
  }

  my $ar = Archive::Libarchive::ArchiveRead->new;
  $ar->support_filter_all;
  $ar->support_format_all;

  my $ret = $ar->open_memory(\$self->{data});
  if($ret == ARCHIVE_WARN)
  {
    warn $ar->error_string;
  }
  elsif($ret < ARCHIVE_WARN)
  {
    warn $ar->error_string;
    return $self->return_500;
  }

  my $html = "<html><head><title>@{[ $self->{title} ]}</title></head><body><ul>";

  my $e = Archive::Libarchive::Entry->new;
  while(1)
  {
    my $ret = $ar->next_header($e);
    if($ret == ARCHIVE_EOF)
    {
      last;
    }
    elsif($ret == ARCHIVE_WARN)
    {
      warn $ar->error_string;
    }
    elsif($ret < ARCHIVE_WARN)
    {
      warn $ar->error_string;
      return $self->return_500;
    }

    my $path = $e->pathname;
    $ar->read_data_skip;
    $html .= "<li><a href=\"$path\">$path</a></li>";
  }

  $html .= "</ul>";

  return [ 200,
         [ 'Content-Type' => 'text/html', 'Content-Length' => length($html) ],
         [ $html ]
  ]
}

sub return_500 ($self)
{
  return [500, ['Content-Type' => 'text/plain', 'Content-Length' => 21], ['Internal Server Error']];
}

sub return_400 ($self)
{
  return [400, ['Content-Type' => 'text/plain', 'Content-Length' => 11], ['Bad Request']];
}

sub return_404 ($self)
{
  return [404, ['Content-Type' => 'text/plain', 'Content-Length' => 9], ['Not Found']];
}

1;
