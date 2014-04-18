package Akamai::Open::Client;
# ABSTRACT: The Akamai Open API Perl client structure for authentication data

use strict;
use warnings;

use Moose;
use Akamai::Open::Debug;

has 'debug'         => (is => 'rw', default => sub{ return(Akamai::Open::Debug->instance());});
has 'client_secret' => (is => 'rw', isa => 'Str', trigger => \&Akamai::Open::Debug::debugger);
has 'client_token'  => (is => 'rw', isa => 'Str', trigger => \&Akamai::Open::Debug::debugger);
has 'access_token'  => (is => 'rw', isa => 'Str', trigger => \&Akamai::Open::Debug::debugger);

1;

__END__

=pod

=encoding utf-8

=head1 SYNOPSIS

 use Akamai::Open::Client;
 use Akamai::Open::DiagnosticTools;

 my $client = Akamai::Open::Client->new();
 $client->access_token('foobar');
 $client->client_token('barfoo');
 $client->client_secret('Zm9vYmFyYmFyZm9v');

 my $req = Akamai::Open::DiagnosticTools->new(client => $client);

=head1 ABOUT

I<Akamai::Open::Client> provides the data structure which holds the 
client specific data which is needed for the authentication process 
against the I<Akamai::Open> API.

This data is provided by Akamai and can be found in your 
L<LUNA control center account|https://control.akamai.com/>, 
inside the I<Manage APIs> tool.

=cut

