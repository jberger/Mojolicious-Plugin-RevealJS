use strict;
use warnings;

use 5.10.1;
use Module::Build;

my $builder = Module::Build->new(
  module_name => 'Mojolicious::Plugin::RevealJS',
  dist_author => 'Joel Berger',
  license => 'perl',

  requires => {
    'perl' => '5.10.1',
    'Mojolicious' => '6.0',  # just a start
    'File::Copy::Recursive' => 0,
  },
  configure_requires => {
    'Module::Build' => 0.38,
  },

  share_dir => 'lib/Mojolicious/Plugin/RevealJS/files',

  meta_merge => {
    resources  => {
      repository => "http://github.com/jberger/Mojolicious-Plugin-RevealJS",
      bugtracker => "http://github.com/jberger/Mojolicious-Plugin-RevealJS/issues",
    },
  }
);

$builder->create_build_script;

