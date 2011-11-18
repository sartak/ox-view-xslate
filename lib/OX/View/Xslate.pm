package OX::View::Xslate;
use Moose;

use MooseX::Types::Path::Class;
use Text::Xslate;

has 'template_root' => (
    is        => 'ro',
    isa       => 'Path::Class::Dir',
    coerce    => 1,
    predicate => 'has_template_root',
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
        my %args;

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
            }
        };

        Text::Xslate->new(
            %args,
            %{ $self->template_config }
        )
    }
);

sub render {
    my ($self, $r, $template, $params) = @_;

    $params = {
        %{ $params || {} },
        m => { $r->mapping },
        r => $r,
    };

    return $self->xslate->render($template, $params);
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
