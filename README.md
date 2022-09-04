# Plack::App::Libarchive ![static](https://github.com/uperl/Plack-App-Libarchive/workflows/static/badge.svg) ![linux](https://github.com/uperl/Plack-App-Libarchive/workflows/linux/badge.svg)

Serve an archive via libarchive as a PSGI web app

# SYNOPSIS

```perl
use Plack::App::Libarchive;
my $app = Plack::App::Libarchive->new( archive => 'foo.tar.tz' )->to_app;
```

# DESCRIPTION

This [PSGI](https://metacpan.org/pod/PSGI) application serves the content of an archive (any format supported
by `libarchive` via [Archive::Libarchive](https://metacpan.org/pod/Archive::Libarchive)).  A request to the root for the
app will return an index of the files contained within the archive.

The index is generated using [Template](https://metacpan.org/pod/Template).  There is a bundled template that
will list the entry files and link to their content.  If you want to customize
the index you can provide your own template.  Here are the template variables
that are available from within the template:

- `archive`

    A hash reference containing information about the archive

- `archive.name`

    The basename of the archive filename.  For example: `foo.tar.gz`.

- `archive.get_next_entry`

    Get the next [Archive::Libarchive::Entry](https://metacpan.org/pod/Archive::Libarchive::Entry) object from the archive.

Here is the default wrapper.html.tt:

```
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>[% archive.name %]</title>
  </head>
  <body>
    [% content %]
  </body>
</html>
```

and the default archive\_index.html.tt

```
<ul>
  [% WHILE (entry = archive.get_next_entry) %]
    <li><a href="[% entry.pathname | uri %]">[% entry.pathname | html %]</a></li>
  [% END %]
</ul>
```

# CONFIGURATION

- archive

    The relative or absolute path to the archive.

- tt

    Instance of [Template](https://metacpan.org/pod/Template) that will be used to generate the html index.  The default
    is:

    ```perl
    Template->new(
      WRAPPER            => 'wrapper.html.tt',
      INCLUDE_PATH       => File::ShareDir::Dist::dist_share('Plack-App-Libarchive'),
      DELIMITER          => ':',
      render_die         => 1,
      TEMPLATE_EXTENSION => '.tt',
      ENCODING           => 'utf8',
    )
    ```

    On `MSWin32` a delimiter of `;` is used instead.

- tt\_include\_path

    Array reference of additional [Template INCLUDE\_PATH directories](https://metacpan.org/pod/Template#INCLUDE_PATH).  This
    id useful for writing your own custom template.

# SEE ALSO

- [Archive::Libarchive](https://metacpan.org/pod/Archive::Libarchive)
- [Plack](https://metacpan.org/pod/Plack)
- [PSGI](https://metacpan.org/pod/PSGI)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
