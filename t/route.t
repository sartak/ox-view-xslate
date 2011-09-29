#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;
use FindBin;

use HTTP::Request::Common;
use Path::Class ();

{
    package Foo;
    use OX;

    has template_root => (
        is    => 'ro',
        isa   => 'Str',
        block => sub {
            Path::Class::dir($FindBin::Bin)->subdir('data', 'route', 'templates', 'foo')->stringify
        },
    );

    has view => (
        is           => 'ro',
        isa          => 'OX::View::TT',
        dependencies => ['template_root'],
    );

    router as {
        route '/' => 'view.template', (
            template => 'index.tt',
        );
        route '/foo' => 'view.template', (
            template => 'foo.tt',
        );
    };
}

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET 'http://localhost/');
            is($res->code, 200, "right code");
            is($res->content, "<b>Hello world</b>\n", "right content");
        }
        {
            my $res = $cb->(GET 'http://localhost/foo');
            is($res->code, 200, "right code");
            is($res->content, "<p>/foo</p>\n", "right content");
        }
    };

{
    package Bar::View;
    use Moose;

    extends 'OX::View::TT';

    around render => sub {
        my $orig = shift;
        my $self = shift;
        my ($r, $template, $params) = @_;
        $params->{my_thing} = 'BAR';
        return $self->$orig(@_);
    };
}

{
    package Bar;
    use OX;

    has template_root => (
        is    => 'ro',
        isa   => 'Str',
        block => sub {
            Path::Class::dir($FindBin::Bin)->subdir('data', 'route', 'templates', 'bar')->stringify
        },
    );

    has view => (
        is           => 'ro',
        isa          => 'Bar::View',
        dependencies => ['template_root'],
    );

    router as {
        route '/' => 'view.template', (
            template => 'index.tt',
        );
        route '/foo' => 'view.template', (
            template => 'foo.tt',
        );
    };
}

test_psgi
    app    => Bar->new->to_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET 'http://localhost/');
            is($res->code, 200, "right code");
            is($res->content, "<b>Hello world: BAR</b>\n", "right content");
        }
        {
            my $res = $cb->(GET 'http://localhost/foo');
            is($res->code, 200, "right code");
            is($res->content, "<p>/foo: BAR</p>\n", "right content");
        }
    };

done_testing;
