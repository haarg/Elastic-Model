package ESModel::Role::Doc;

use Moose::Role;
with 'ESModel::Role::ModelAttr';

use namespace::autoclean;
use ESModel::Trait::Exclude;
use MooseX::Types::Moose qw(Bool HashRef);
use ESModel::Types qw(Timestamp UID);
use Scalar::Util qw(refaddr);
use Time::HiRes();
use Carp;

#===================================
has 'uid' => (
#===================================
    isa     => UID,
    is      => 'ro',
    traits  => ['ESModel::Trait::Exclude'],
    handles => {
        index   => 'index',
        id      => 'id',
        type    => 'type',
        routing => 'routing'
    },
);

#===================================
has '_inflated' => (
#===================================
    isa    => Bool,
    is     => 'ro',
    traits => ['ESModel::Trait::Exclude'],
);

#===================================
has '_source' => (
#===================================
    isa     => HashRef,
    is      => 'ro',
    traits  => ['ESModel::Trait::Exclude'],
    lazy    => 1,
    builder => '_fetch_source',
);

#===================================
sub _fetch_source {
#===================================
    my $self = shift;
    $self->model->get_raw_doc( $self->uid );
}

#===================================
around 'BUILDARGS' => sub {
#===================================
    my $orig   = shift;
    my $class  = $_[0];
    my $params = $orig->(@_);

    my $uid = $params->{uid};
    if ( $uid and $uid->from_store ) {
        delete $params->{_source} unless $params->{_source};
    }
    else {
        $params->{_inflated} = 1;
        my $required = $class->meta->required_attrs;
        for my $name ( keys %$required ) {
            croak "Attribute ($name) is required"
                unless $params->{ $required->{$name} };
        }
    }
    return $params;
};

#===================================
sub _load_data {
#===================================
    my $self = shift;

    my $uid   = $self->uid;
    my $model = $self->model;

    # TODO: what if doc deleted?
    my $source = $self->_source;

    my $new = $self->new(
        model => $model,
        uid   => $uid,
        %{ $self->inflate($source) },
        _inflated =>1,
    );

    %$self = %$new;
    return;
}

#===================================
has timestamp => (
#===================================
    traits  => ['ESModel::Trait::Field'],
    isa     => Timestamp,
    is      => 'rw',
    exclude => 0
);

no Moose::Role;

#===================================
sub touch { shift->timestamp( int( Time::HiRes::time * 1000 + 0.5 ) / 1000 ) }
#===================================

#===================================
sub save {
#===================================
    my $self = shift;
    my %args = ref $_[0] ? %{ shift() } : @_;

    $self->touch if $self->meta->timestamp_path;

    my $uid = $self->uid;
    my $action = $uid->from_store ? 'index_doc' : 'create_doc';

    my $result = $self->model->store->$action( $uid, $self->deflate, \%args );
    $self->uid->update_from_store($result);
    $self;
}

#===================================
sub delete {
#===================================
    my $self   = shift;
    my %args   = ref $_[0] ? %{ shift() } : @_;
    my $result = $self->model->store->delete_doc( $self->uid, \%args );
    $self->uid->update_from_store($result);
    $self;
}


1;
