use 5.014;

package Plack::Middleware::CSP 0.03 {
    use utf8;
    use strict;
    use warnings;
    use HTTP::CSPHeader;
    use parent "Plack::Middleware";
    use Plack::Util::Accessor qw( nonce_template_token );
    our $AUTHORITY = "cpan:ASHLEY";

    sub _csp { +shift->{_csp} }
    sub _nonce { +shift->_csp->nonce }

    sub new {
        my $self = +shift->SUPER::new(@_);
        # Let HTTP::CSPHeader decide and report on arguments.
        $self->{_csp} = HTTP::CSPHeader->new(
            policy => delete $self->{policy},
            nonces_for => delete $self->{nonces_for},
            );

        $self;
    }

    sub call {
        my ( $self, $env ) = @_;

        $env->{"CSP_NONCE"} = $self->_nonce;
        my $res = $self->app->($env);

        Plack::Util::response_cb($res, sub {
            my $res = shift;
            $self->_csp->reset; # Request is done, reset for response.
            my $h = Plack::Util::headers($res->[1]);
            if ( my $token = $self->nonce_template_token )
            {
                my $nonce = $self->_nonce;
                # Content type?!? Restrict to… sane values? text, html…?
                s/\Q$token/$nonce/g for @{ $res->[2] };
            }
            $h->set("content-security-protocol" => $self->_csp->header );
         });
    }
    1;
};

__DATA__

=pod

=encoding utf8

=head1 Name

Plack::Middleware::CSP - Apply L<HTTP::CSPHeader> to your psgi application.

=head1 Synopsis

 use utf8;
 use strict;
 use warnings;
 use Plack::Builder;
 use Plack::Middleware::CSP;

 my $app = sub {
     my $env = shift;
     [ 200,
       [ "content-type" => "text/plain; charset=utf-8" ],
       [ "OHAI $env->{CSP_NONCE}" ] ]
 };

 # CSP middleware takes the arguments for HTTP::CSPHeader.
 builder {
     enable "CSP" =>
         policy => {
             'default-src' => q['self'],
             'script-src'  => q['self'],
         }, nonces_for => 'script-src';

     mount "/" => $app;
 };

Test it–

 plackup app.psgi

See the headers–

 curl -I http://0:5000/

=head2 policy, nonces_for

Refer to L<HTTP::CSPHeader>’s documentation.

=head2 $env->{CSP_NONCE}

The nonce for the response is in the psgi environment as CSP_NONCE.

=head2 nonce_template_token

There is an B<experimental> feature to do automatic nonce
substitutions in the response body, for example in a template. It is
experimental because it might be a terrible idea and even if it's a
good idea, it almost certainly needs to be much less liberal with its
approach. It should probably require the calling code to declare
target content type. Adding it into our synopsis–

 use utf8;
 use strict;
 use warnings;
 use Plack::Builder;
 use Plack::Middleware::CSP;

 my $app = sub { [ 200,
                  [ "content-type" => "text/plain; charset=utf-8" ],
                  [ "DIS IZ MAI NONCE: ::nonce::!" ] ] };

 builder {
     enable "CSP" =>
         nonce_template_token => "::nonce::",
         policy => {
             'default-src' => q['self'],
             'script-src'  => q['self'],
         }, nonces_for => 'script-src';

     mount "/" => $app;
 };

=head1 RFC

I put this together just to work on some security testing for myself.
It's alpha, unreviewed code, only tested on simplistic cases. It
almost certainly has bugs.

Please submit any patches, tests, feedback, or issues through its
repo, L<https://github.com/pangyre/Plack-Middleware-CSP/issues>.

=head1 See Also

The excellent Leon Timmermans took a stab at this quite a few years
ago: L<https://github.com/Leont/plack-middleware-csp>. I have not made
any tests or comparisons.

L<HTTP::CSPHeader>, L<Plack>, L<Plack::Middleware>, L<Plack::Util>.

L<https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP>.

=head1 Author

Ashley Pond V, C<< <ashley@cpan.org> >>.

=head1 License

©2022 Ashley Pond V. This program is free software; you can
redistribute it and modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>.

=cut

To do–

csp-report => {}

