package ESModel::Result;

use Moose;

use ESModel::Types qw(UID);
use MooseX::Types::Moose qw(:all);

use namespace::autoclean;

has 'result' => (
    isa      => HashRef,
    is       => 'ro',
    required => 1,
);

has 'uid' => (
    isa     => UID,
    is      => 'ro',
    lazy    => 1,
    builder => '_build_uid',
);

no Moose;

#===================================
sub _build_uid {
#===================================
    my $self = shift;
    ESModel::UID->new_from_store( $self->result );
}

#===================================
sub object {
#===================================
    my $self = shift;
    $self->model->get_doc(
        uid     => $self->uid,
        _source => $self->source

    );
}

#===================================
sub source { shift->result->{_source} }
sub score  { shift->result->{_score} }
#===================================

#===================================
sub fields        { shift->result->{fields}        ||= {} }
sub script_fields { shift->result->{script_fields} ||= {} }
sub highlight     { shift->result->{highlight}     ||= {} }
#===================================

1;
