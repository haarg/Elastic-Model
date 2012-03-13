package ESModel::Meta::Class;

use Moose::Role;
use MooseX::Types::Moose qw(Str);
use namespace::autoclean;


#===================================
has 'model' => (
#===================================
    traits   => ['ESModel::Trait::Exclude'],
    does     => 'ESModel::Role::Model',
    is       => 'ro',
    writer   => '_set_model',
    weak_ref => 1,
);

#===================================
has 'original_class' => (
#===================================
    is     => 'ro',
    isa    => Str,
    writer => '_set_original_class',
);

1;