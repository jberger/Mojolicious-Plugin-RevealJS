package Mojolicious::Plugin::RevealJS;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.05';
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
  push @{ $app->static->paths },   $home->rel_file('public');
  push @{ $app->renderer->paths }, $home->rel_file('templates');

  $app->defaults('revealjs.init' => {
    controls => \1,
    progress => \1,
    history  => \1,
    center   => \1,
    transition => 'slide', #none/fade/slide/convex/concave/zoom
  });

  $app->helper('include_code' => \&_include_code);
  $app->helper('revealjs.export' => \&_export);
}

sub _include_code {
  my ($c, $file) = (shift, shift);
  my $html = $c->render_to_string(inline => <<'  INCLUDE', 'revealjs.private.file' => $file, @_);
    % require Mojo::Util;
    % my $file = stash 'revealjs.private.file';
    <pre><code class="<%= stash('language') // 'perl' %>" data-trim>
      <%= Mojo::File::slurp(app->home->rel_file($file)) =%>
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

=head3 stash paramters

It accepts the stash parameters:

=over

=item *

author - sets the metadata value

=item *

description - sets the metadata value

=item *

init - Reveal.js initialization options, a hashref for JSON conversion documented below

=item *

theme - a string representing a theme css to be included.
If the string ends in C<.css> it is included literally, otherwise it is assumed to be the name of a bundled Reveal.js theme.
Bundled themes are: black, white, league, beige, sky, night, serif, simple, solarized.
Defaults to black.
See more on the L<"Reveal.js page"|https://github.com/hakimel/reveal.js#theming>.

=item *

title - sets the window title, not used on the title slide

=back

=head3 initialization parameters

As mentioned above, the stash key C<init> is a hashref that is merge into a set of defaults and used to initialize Reveal.js.
Some RevealJS initialization options, specifically those that have a default are:

=over

=item *

center - enable slide centering (boolean, true by default)

=item *

controls - enable controls (boolean, true by default)

=item *

history - enable history (boolean, true by default)

=item *

progress - enable progress indicator (boolean, true by default)

=item *

transition - set the slide transition type (one of: none, fade, slide, convex, concave, zoom; default: slide)

=back

These defaults are set in the default stash value for C<revealjs.init>.
So they can be modified globally modifying that value (probably during setup).

  $app->defaults->{'revealjs.init'}{transition} = 'none';

Note that booleans are references to scalar values, C<true == \1>, C<false == \0>.
See more availalbe options on the L<"Reveal.js page"|https://github.com/hakimel/reveal.js#configuration>.

=head3 additional templates

In order to further customize the template the following unimplemented templates are included into the layout

=over

=item *

C<revealjs_head.html.ep> - included at the end of the C<< <head> >> tag.

=item *

C<revealjs_preinit.js.ep> - included just before initializing Reveal.js.
Especially useful to modify the javascript variable C<init>.

=item *

C<revealjs_body.html.ep> - included at the end of the C<< <body> >> tag.

=back

=head1 HELPERS

=head2 include_code

  %= include_code 'path/to/file.pl'

This helper does several things:

=over

=item *

localizes trailing arguments into the stash

=item *

slurps a section of code

=item *

sets the language to the value of C<< stash('language') // 'perl' >>

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
