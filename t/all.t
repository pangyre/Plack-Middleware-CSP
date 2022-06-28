#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
# use open ":std", ":encoding(utf8)";
use Test::More "no_plan";
use Plack::Test;
use HTTP::Request::Common;
use Path::Tiny;

my $test_file = path(__FILE__);
my $module_file = path( $test_file->parent->parent, "lib/Plack/Middleware/CSP.pm" );
ok -e $module_file, "Got the module file";
my $code = $module_file->slurp_utf8;

# Loads test code from the .pm. If you edit the relevant parts, you’ll
# need to update the tests–

subtest "Test first synopsis" => sub {
    my ( $synopsis ) = $code =~ /=head1 Synopsis(.+?)(?=\n\r?\w)/s;
    ok $synopsis, "Pulled first synopsis out of pod";
    # note $synopsis;
    ok my $app = eval $synopsis, "Synopsis code compiles";

    test_psgi $app, sub {
          my $cb  = shift;
          my $res = $cb->(GET "/");

          like $res->header("content-security-protocol"), qr/script-src 'self'/,
              q{Header contains "script-src 'self'"};

          like $res->header("content-security-protocol"), qr/default-src 'self'/,
              q{Header contains "default-src 'self'"};

          my ( $nonce ) = $res->header("content-security-protocol") =~ /nonce-([a-f0-9]+)/;

          ok $nonce, "Got nonce out of the content-security-protocol header";

          is $res->content, "OHAI $nonce", "App delivers page with proper nonce";
      };
    
    done_testing(6);
};

# subtest "Test second synopsis" => sub {}

done_testing(2);

__END__

