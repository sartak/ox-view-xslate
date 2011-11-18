package OX::View::Xslate;
use Moose;

use MooseX::Types::Path::Class;
use Text::Xslate;

has 'template_root' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    required => 1,
);

has 'template_config' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
);

has 'xslate' => (
    is      => 'ro',
    isa     => 'Text::Xslate',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Text::Xslate->new(
            INCLUDE_PATH => $self->template_root,
            %{ $self->template_config }
        )
    }
);

sub _build_template_params {
    my ($self, $r, $params) = @_;
    return +{
        base    => $r->script_name,
        uri_for => sub { $r->uri_for(@_) },
        m       => { $r->mapping },
        %{ $params || {} }
    }
}

sub render {
    my ($self, $r, $template, $params) = @_;
    my $out = '';
    $self->xslate->process(
        $template,
        $self->_build_template_params( $r, $params ),
        \$out
    ) || confess $self->xslate->error;
    $out;
}

sub template {
    my $self = shift;
    my ($r) = @_;

    my %params = $r->mapping;
    confess("Must supply a 'template' parameter")
        unless exists $params{template};

    return $self->render($r, $params{template});
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

OX::View::Xslate - A Moosey solution to this problem

=head1 SYNOPSIS

  use OX::View::Xslate;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
