use Mojolicious::Lite;

plugin 'RevealJS';

any '/' => { template => 'mytalk' };

app->start;

