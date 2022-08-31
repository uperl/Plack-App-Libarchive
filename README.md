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

# CONFIGURATION

- archive

    The relative or absolute path to the archive.

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
