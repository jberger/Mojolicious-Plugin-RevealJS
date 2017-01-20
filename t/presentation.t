use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

plugin 'RevealJS';

get '/' => {
  template => 'hello_talk',
  layout => 'revealjs',
  title => 'Hello World!',
  author => 'JBERGER',
  description => 'Everybody ❤️ Mojolicious',
};

under '/reveal';

get '/nested_route' => { 
  template => 'hello_talk',
  layout => 'revealjs',
  title => 'Hello World!',
  author => 'JBERGER',
  description => 'Everybody ❤️ Mojolicious',
};

my $t = Test::Mojo->new;

$t->get_ok('/')
  ->status_is(200)
  ->text_is(title => 'Hello World!')
  ->element_exists('meta[name="author"][content="JBERGER"]')
  ->element_exists('meta[name="description"][content="Everybody ❤️ Mojolicious"]')
  ->text_is('.reveal .slides section:nth-child(1) h1' => 'A Mojolicious Hello World!')
  ->text_like('.reveal .slides section:nth-child(2) pre code.perl' => qr/use Mojolicious::Lite;/)
  ->text_is('.reveal .slides section:nth-child(2) p' => 'code/hello.pl')
  ->element_exists('.reveal .slides pre code.html', 'language class applied')
  ->element_exists_not('.reveal .slides pre code.html #raw', 'contents of included files are html escaped');

$t->get_ok('/reveal/nested_route')
  ->status_is(200)
	->element_exists('link[href="/revealjs/css/reveal.css"]')
	->element_exists('script[src="/revealjs/lib/js/head.min.js"]');

done_testing;

__DATA__

@@ hello_talk.html.ep

<section>
  <h1>A Mojolicious Hello World!</h1>
</section>

<section>
  %= include_code 'code/hello.pl'
</section>

<section>
  %= include_code 'code/raw.html', language => 'html'
<section>

