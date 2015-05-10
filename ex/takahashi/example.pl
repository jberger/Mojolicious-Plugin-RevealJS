use Mojolicious::Lite;

plugin 'RevealJS';

helper line => sub { shift->tag(span => class => slabtext => @_ ) };

any '/' => { template => 'mytalk', layout => 'revealjs', transition => 'none', progress => 0 };

app->start;

