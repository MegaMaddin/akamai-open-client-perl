use Test::More;

BEGIN {
    use_ok('Akamai::Open::Client');
}
require_ok('Akamai::Open::Client');

my $client = new_ok('Akamai::Open::Client');
ok($client->access_token('foobar'),             'setting access_token');
ok($client->client_token('barfoo'),             'setting client_token');
ok($client->client_secret('Zm9vYmFyYmFyZm9v'),  'setting client_secret');

is($client->access_token, 'foobar',             'getting access_token');
is($client->client_token, 'baarfoo',             'getting client_token');
is($client->client_secret, 'Zm9vYmFyYmFyZm9v',  'getting client_secret');

done_testing;
