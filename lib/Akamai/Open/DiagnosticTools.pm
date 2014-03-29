package Akamai::Open::DiagnosticTools;

BEGIN {
    $Akamai::Open::DiagnosticTools::AUTHORITY = 'cpan:PROBST';
}
{
    $Akamai::Open::DiagnosticTools::VERSION = '0.01';
}
# ABSTRACT: The Akamai Open DiagnosticTools API Perl client

use strict;
use warnings;
use feature qw/switch/;

use Moose;
use JSON;

#XXX create a useful scheme for REST methods
use constant {
    TOOLS_URI  => '/diagnostic-tools',
    DIG_URI    => '/v1/dig',
    MTR_URI    => '/v1/mtr',
    LOC_URI    => '/v1/locations'
};

extends 'Akamai::Open::Request::EdgeGridV1';

has 'tools_uri' => (is => 'ro', default => TOOLS_URI);
has 'dig_uri'   => (is => 'ro', default => DIG_URI);
has 'mtr_uri'   => (is => 'ro', default => MTR_URI);
has 'loc_uri'   => (is => 'ro', default => LOC_URI);
has 'baseurl'   => (is => 'rw', trigger => \&Akamai::Open::Debug::debugger);
has 'last_error'=> (is => 'rw');

sub validate_base_url {
    my $self = shift;
    my $base = $self->baseurl();
    $self->debug->logger->debug('validating baseurl');
    $base =~ s{/$}{} && $self->baseurl($base);
    return;
}
 
foreach my $f (qw/dig mtr locations/) {
    before $f => sub {
        my $self = shift;
        my $param = @_;

        $self->validate_base_url();
        my $uri = $self->baseurl() . $self->tools_uri();

        $self->debug->logger->debug("before hook called for $f") if($self->debug->logger->is_debug());

        #XXX create a useful scheme for REST methods
        given($f) {
            when($_ eq 'dig') {
                $uri .= $self->dig_uri();
                $self->request->method('GET');
            }
            when($_ eq 'mtr') {
                $uri .= $self->mtr_uri();
                $self->request->method('GET');
            }
            when($_ eq 'locations') {
                $uri .= $self->loc_uri();
                $self->request->method('GET');
            }
        }

        $self->debug->logger->info('filling request object with data');
        $self->request->uri(URI->new($uri));
    };
}

sub dig {
    my $self = shift;
    my $param = shift;
    my $valid_types_re = qr/^(?i:A|AAAA|PTR|SOA|MX|CNAME)$/;
    my $data;

    $self->debug->logger->debug('dig() was called');

    unless(ref($param)) {
        $self->last_error('parameter of dig() has to be a hashref');
        $self->debug->logger->error($self->last_error());
        return(undef);
    }

    unless(defined($param->{'hostname'}) && defined($param->{'queryType'})) {
        $self->last_error('hostname and queryType are mandatory options for dig()');
        $self->debug->logger->error($self->last_error());
        return(undef);
    }

    unless($param->{'queryType'} =~ m/$valid_types_re/) {
        $self->last_error('queryType has to be one of A, AAAA, PTR, SOA, MX or CNAME');
        $self->debug->logger->error($self->last_error());
        return(undef);
    }

    unless(defined($param->{'location'}) || defined($param->{'sourceIp'})) {
        $self->last_error('either location or sourceIp has to be set');
        $self->debug->logger->error($self->last_error());
        return(undef);
    }

    $self->request->uri->query_form($param);
    $self->sign_request();
    $self->response($self->user_agent->request($self->request()));

    $self->debug->logger->info(sprintf('HTTP response code for dig() call is %s', $self->response->code()));
    $data = decode_json($self->response->content());
    given($self->response->code()) {
        when($_ == 200) {
            if(defined($data->{'dig'}->{'errorString'})) {
                $self->last_error($data->{'dig'}->{'errorString'});
                $self->debug->logger->error($self->last_error());
                return(undef);
            } else {
                return($data->{'dig'});
            }
        }
        when($_ =~m/^5\d\d/) {
            $self->last_error('the server returned a 50x error');
            $self->debug->logger->error($self->last_error());
            return(undef);
        }
    }
    $self->last_error(sprintf('%s %s %s', $data->{'httpStatus'} ,$data->{'title'} ,$data->{'problemInstance'}));
    $self->debug->logger->error($self->last_error());
    return(undef);
}

sub mtr {
    my $self = shift;
    my $param = shift;
    my $data;

    $self->debug->logger->debug('mtr() was called');

    unless(ref($param)) {
        $self->last_error('parameter of mtr() has to be a hashref');
        $self->debug->logger->error($self->last_error());
        return(undef);
    }

    unless(defined($param->{'destinationDomain'})) {
        $self->last_error('destinationDomain is a mandatory options for mtr()');
        $self->debug->logger->error($self->last_error());
        return(undef);
    }

    unless(defined($param->{'location'}) || defined($param->{'sourceIp'})) {
        $self->last_error('either location or sourceIp has to be set');
        $self->debug->logger->error($self->last_error());
        return(undef);
    }

    $self->request->uri->query_form($param);
    $self->sign_request();
    $self->response($self->user_agent->request($self->request()));

    $self->debug->logger->info(sprintf('HTTP response code for mtr() call is %s', $self->response->code()));
    $data = decode_json($self->response->content());
    given($self->response->code()) {
        when($_ == 200) {
            if(defined($data->{'mtr'}->{'errorString'})) {
                $self->last_error($data->{'mtr'}->{'errorString'});
                $self->debug->logger->error($self->last_error());
                return(undef);
            } else {
                return($data->{'mtr'});
            }
        }
        when($_ =~m/^5\d\d/) {
            $self->last_error('the server returned a 50x error');
            $self->debug->logger->error($self->last_error());
            return(undef);
        }
    }
    $self->last_error(sprintf('%s %s %s', $data->{'httpStatus'} ,$data->{'title'} ,$data->{'problemInstance'}));
    $self->debug->logger->error($self->last_error());
    return(undef);
}

sub locations {
    my $self = shift;
    my $data;

    $self->debug->logger->debug('locations() was called');
    $self->sign_request();
    $self->response($self->user_agent->request($self->request()));
    $self->debug->logger->info(sprintf('HTTP response code for locations() call is %s', $self->response->code()));
    $data = decode_json($self->response->content());
    given($self->response->code()) {
        when($_ == 200) {
            if(defined($data->{'errorString'})) {
                $self->last_error($data->{'errorString'});
                $self->debug->logger->error($self->last_error());
                return(undef);
            } else {
                return($data->{'locations'});
            }
        }
        when($_ =~m/^5\d\d/) {
            $self->last_error('the server returned a 50x error');
            $self->debug->logger->error($self->last_error());
            return(undef);
        }
    }
    $self->last_error(sprintf('%s %s %s', $data->{'httpStatus'} ,$data->{'title'} ,$data->{'problemInstance'}));
    $self->debug->logger->error($self->last_error());
    return(undef);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Akamai::Open::DiagnosticTools - The Akamai Open DiagnosticTools API Perl client

=head1 SYNOPSIS

 use Akamai::Open::Client;
 use Akamai::Open::DiagnosticTools;

 my $client = Akamai::Open::Client->new();
 $client->access_token('foobar');
 $client->client_token('barfoo');
 $client->client_secret('Zm9vYmFyYmFyZm9v');

 my $req = Akamai::Open::DiagnosticTools->new(client => $client);

=head1 ABOUT

I<Akamai::Open::DiagnosticTools> provides an API client for the 
Akamai Open DiagnosticTools API which is described L<here|https://developer.akamai.com/api/luna/diagnostic-tools/reference.html>.

=head1 USAGE

TBD

=head1 AUTHOR

Martin Probst <internet+cpan@megamaddin.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Martin Probst.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

