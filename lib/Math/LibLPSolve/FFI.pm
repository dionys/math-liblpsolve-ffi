package Math::LibLPSolve::FFI;

use strict;
use warnings;

use File::Spec::Functions qw(catdir);
use FFI::CheckLib ();
use FFI::Platypus ();

use namespace::clean;


{
    my $ffi;

    sub _ffi {
        return $ffi if $ffi;

        $ffi = FFI::Platypus->new;

        $ffi->find_lib(
            lib     => 'lpsolve55',
            libpath => [map { catdir($_, 'lp_solve') } @$FFI::CheckLib::system_path],
        );

        return $ffi;
    }
}

{
    my $ffi = _ffi();

    for (
        [delete_lp => ['int']                     => 'void'],
        [make_lp   => ['int', 'int']              => 'int'],
        [read_LP   => ['string', 'int', 'string'] => 'int'],
        [solve     => ['int']                     => 'int'],
    ) {
        $ffi->attach([$_->[0] => '_ffi_' . $_->[0]] => @$_[1 .. $#$_]);
    }
}

sub new {
    my $proto = shift();
    my $self  = bless({}, ref($proto) || $proto);
    my %args  = @_;

    if ($args{file}) {
        $self->{lp} = _ffi_read_LP($args{file}, 6, undef);
    }
    else {
        $self->{lp} = _ffi_make_lp(0, 0);
    }

    return $self;
}

sub DESTROY {
    my ($self) = @_;

    _ffi_delete_lp($self->{lp});
    undef($self->{lp});

    return;
}

sub solve {
    my ($self) = @_;

    my $ret = _ffi_solve($self->{lp});

    return $ret;
}


1;
