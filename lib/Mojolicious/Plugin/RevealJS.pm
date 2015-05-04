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
