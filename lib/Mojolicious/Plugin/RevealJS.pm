package Mojolicious::Plugin::RevealJS;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';
$VERSION = eval $VERSION;

use Mojo::Home;
use Mojo::ByteStream 'b';

use File::Basename 'dirname';
use File::Spec::Functions qw/rel2abs catdir/;
use File::ShareDir 'dist_dir';

has home => sub {
  my $checkout = catdir(dirname(rel2abs(__FILE__)), qw/RevealJS files/);
  Mojo::Home->new(-d $checkout ? $checkout : dist_dir('Mojolicious-Plugin-RevealJS'));
};

sub register {
  my ($plugin, $app, $conf) = @_;
  my $home = $plugin->home;
  push @{ $app->static->paths },   $home->rel_dir('public');
  push @{ $app->renderer->paths }, $home->rel_dir('templates');

  #$conf->{layout} = 'revealjs' unless exists $conf->{layout};
  #if (defined(my $layout = $conf->{layout})) {
    #$app->defaults(layout => $layout);
  #}

  $app->helper('include_code' => \&_include_code);
  $app->helper('revealjs.export' => \&_export);
}

sub _include_code {
  my ($c, $file) = @_;
  my $html = $c->render_to_string(inline => <<'  INCLUDE', file => $file);
    % require Mojo::Util;
    <pre><code class="perl" data-trim>
      <%= Mojo::Util::slurp(app->home->rel_file($file)) =%>
    </code></pre>
    <p style="float: right; text-color: white; font-size: small;"><%= $file %></p>
  INCLUDE
  return b $html;
}

sub _export {
  my ($c, $page, $to) = @_;
  require Mojo::Util;
  require File::Copy::Recursive;
  File::Copy::Recursive->import('dircopy');
  File::Copy::Recursive::pathmk($to);

  my $body = $c->ua->get($page)->res->body;
  Mojo::Util::spurt($body => File::Spec->catfile($to, 'index.html'));
  for my $path( @{ $c->app->static->paths } ) {
    dircopy($path, $to);
  }
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::RevealJS - Mojolicious ❤️ Reveal.js

=head1 SYNOPSIS

  use Mojolicious::Lite;

  plugin 'RevealJS';

  any '/' => { template => 'mytalk', layout => 'revealjs' };

  app->start;

=head1 DESCRIPTION

L<Mojolicious::Plugin::RevealJS> is yet another attempt at making presentations with L<Mojolicious>.
While the author's previous attempts have tried do too much, this one simply makes it easier to use L<Reveal.js|http://lab.hakim.se/reveal-js>.
It provides a layout (C<revealjs>) which contains the boilerplate and loads the bundled libraries.
It also provides a few simple helpers.
Future versions of the plugin will allow setting of configuration like themes.

The bundled version of Reveal.js is currently 3.0.0.

Note that this module is in an alpha form!
The author makes no compatibilty promises.

=head1 LAYOUTS

  # controller
  $c->layout('revealjs'); # or
  $c->stash(layout => 'revealjs');

  # or template
  % layout 'revealjs';

=head2 revealjs

This layout is essentially the standard template distributed as part of the Reveal.js tarball.
It is modified for use in a Mojolicious template.

It accepts the stash parameters C<title>, C<author> and C<description> which set the header (metadata) values you would expect.

=head1 HELPERS

=head2 include_code

  %= include_code 'path/to/file.pl'

This helper does several things:

=over

=item *

slurps a section of code

=item *

sets the language (currently sets the format to perl, though this is likely to change)

=item *

http escapes the content

=item *

applies some simple formatting

=item *

displays the relative path to the location of the file (for the benefit of repo cloners)

=back

At this point very little of it is configurable and that is likely to change (possibly incompatibly)

=head2 revealjs->export

  $ ./myapp.pl eval 'app->revealjs->export("/" => "path/")'

Exports the rendered page and all of the files in the static directories to the designated path.
This is very crude, but effective for usual cases.

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojolicious-Plugin-RevealJS>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Reveal.js (bundled) is Copyright (C) 2015 Hakim El Hattab, http://hakim.se and released under the MIT license.
