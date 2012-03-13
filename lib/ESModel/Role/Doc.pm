package ESModel::Role::Doc;

use Moose::Role;

use ESModel::Trait::Exclude;
use MooseX::Types::Moose qw(Bool HashRef);
use ESModel::Types qw(Timestamp UID);
use Scalar::Util qw(refaddr);
use Time::HiRes();
use Carp;
use namespace::autoclean;

#===================================
has 'uid' => (
#===================================
    isa      => UID,
    is       => 'ro',
    required => 1,
    traits   => ['ESModel::Trait::Exclude'],
    handles  => {
        index   => 'index',
        id      => 'id',
        type    => 'type',
        routing => 'routing'
    },
);

#===================================
has '_can_inflate' => (
#===================================
    isa     => Bool,
    is      => 'rw',
    default => 0,
    traits  => ['ESModel::Trait::Exclude'],
);

#===================================
has '_source' => (
#===================================
    isa     => HashRef,
    is      => 'ro',
    traits  => ['ESModel::Trait::Exclude'],
    lazy    => 1,
    builder => '_get_source',
);

#===================================
sub _get_source {
#===================================
    my $self = shift;
    $self->meta->model->get_raw_doc( $self->uid );
}

#===================================
sub _inflate_doc {
#===================================
    my $self   = shift;
    my $source = $self->_source;
    $self->_can_inflate(0);
    $self->meta->model->inflate_object( $self, $source );
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
    $self->meta->model->save_doc( $self, \%args );
}

#===================================
sub delete {
#===================================
    my $self = shift;
    $self->meta->model->delete_doc( $self, @_ );
}

1;
