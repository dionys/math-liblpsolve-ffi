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
        [copy_lp   => ['uint']                     => 'uint'],
        [delete_lp => ['uint']                     => 'void'],
        [make_lp   => ['uint', 'uint']             => 'uint'],
        [read_LP   => ['string', 'uint', 'string'] => 'uint'],
        [solve     => ['uint']                     => 'uint'],
    ) {
        $ffi->attach([$_->[0] => '_ffi_' . $_->[0]] => @$_[1 .. $#$_]);
    }
}

sub new {
    my $proto = shift();
    my %args  = @_;
    my $lps;

    if ($args{file}) {
        $lps = _ffi_read_LP($args{file}, 6, undef);
    }
    else {
        $lps = _ffi_make_lp(0, 0);
    }

    return unless $lps;
    return bless(\$lps, ref($proto) || $proto);
}

sub DESTROY {
    my ($self) = @_;

    _ffi_delete_lp($$self);
    undef($$self);

    return;
}

sub clone {
    my ($self) = @_;

    my $lps = _ffi_copy_lp($$self);

    return unless $lps;
    return bless(\$lps, ref($self));
}

*copy = \&clone;

sub solve {
    my ($self) = @_;

    my $ret = _ffi_solve($$self);

    return $ret;
}


1;
