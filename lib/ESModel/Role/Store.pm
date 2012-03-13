package ESModel::Role::Store;

use Moose::Role;

use ESModel::Types qw(ES);
use namespace::autoclean;

#===================================
has 'es' => (
#===================================
    isa      => ES,
    is       => 'ro',
    required => 1,
);

#===================================
sub search          { shift->es->search(@_) }
sub scrolled_search { shift->es->scrolled_search(@_) }
#===================================

#===================================
sub get_doc {
#===================================
    my ( $self, $uid ) = @_;
    return $self->es->get(
        fields => [qw(_routing _parent _source)],
        %{ $uid->as_params }
    );
}

#===================================
sub create_doc { shift->_write_doc( 'create', @_ ) }
sub index_doc  { shift->_write_doc( 'index',  @_ ) }
#===================================

#===================================
sub _write_doc {
#===================================
    my ( $self, $action, $uid, $data, $args ) = @_;
    return $self->es->$action(
        data => $data,
        %{ $uid->as_version_params },
        %$args
    );
}

#===================================
sub delete_doc {
#===================================
    my ( $self, $uid, $args ) = @_;
    return $self->es->delete( %{ $uid->as_version_params }, %$args );
}

1;
