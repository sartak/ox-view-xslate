package OX::View::Xslate;
use Moose;

use MooseX::Types::Path::Class;
use Text::Xslate;

has template_root => (
    is        => 'ro',
    isa       => 'Path::Class::Dir',
    coerce    => 1,
    predicate => 'has_template_root',
);

has cache_dir => (
    is        => 'ro',
    isa       => 'Path::Class::Dir',
    coerce    => 1,
    predicate => 'has_cache_dir',
);

has template_config => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
);

has functions => (
    is      => 'ro',
    isa     => 'HashRef[CodeRef]',
    default => sub { +{} },
);

has xslate => (
    is      => 'ro',
    isa     => 'Text::Xslate',
    lazy    => 1,
    default => sub { Text::Xslate->new(shift->_build_xslate_config) }
);

sub _build_xslate_config {
    my $self = shift;
    my %args;

    $args{cache_dir} = $self->cache_dir->stringify
        if $self->has_cache_dir;

    $args{path} ||= [];
    push @{ $args{path} }, $self->template_root->stringify
        if $self->has_template_root;

    push @{ $args{path} }, {
        '_header.tx' => ": macro uri_for ->(\$x) { _uri_for(\$r, \$x) }\n"
    };
    $args{header} = ['_header.tx'];

    $args{function} = {
        _uri_for => sub {
            my ($r, $spec) = @_;
            return $r->uri_for($spec);
        },
        %{ $self->functions },
    };

    return {
        %args,
        %{ $self->template_config },
    };
}

sub _build_render_params {
    my ($self, $r, $template, $params) = @_;

    $params = {
        %{ $params || {} },
        m => { $r->mapping },
        r => $r,
    };

    return $params;
}

sub render {
    my $self = shift;
    my ($r, $template, $params) = @_;

    return $self->xslate->render($template, $self->_build_render_params(@_));
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

=head1 NAME

OX::View::Xslate

=cut
