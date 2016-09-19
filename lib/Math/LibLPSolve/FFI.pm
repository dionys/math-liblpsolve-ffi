package Math::LibLPSolve::FFI;

use strict;
use warnings;

use File::Spec::Functions qw(catdir);
use FFI::CheckLib ();
use FFI::Platypus ();

use namespace::clean;

use Exporter qw(import);


our %EXPORT_TAGS = (
    constants => [qw(
        VERBOSE_NEUTRAL
        VERBOSE_CRITICAL
        VERBOSE_SEVERE
        VERBOSE_IMPORTANT
        VERBOSE_NORMAL
        VERBOSE_DETAILED
        VERBOSE_FULL
    )],
);
our @EXPORT = map { @$_ } values(%EXPORT_TAGS);


use constant VERBOSE_NEUTRAL   => 0;
use constant VERBOSE_CRITICAL  => 1;
use constant VERBOSE_SEVERE    => 2;
use constant VERBOSE_IMPORTANT => 3;
use constant VERBOSE_NORMAL    => 4;
use constant VERBOSE_DETAILED  => 5;
use constant VERBOSE_FULL      => 6;


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
        [copy_lp     => ['uint']                    => 'uint'],
        [delete_lp   => ['uint']                    => 'void'],
        [get_verbose => ['uint']                    => 'int'],
        [make_lp     => ['int', 'int']              => 'uint'],
        [read_LP     => ['string', 'int', 'string'] => 'uint'],
#        [read_lp   => ['uint', 'uint', 'string']   => 'uint'],
        [set_verbose => ['uint', 'int']             => 'void'],
        [solve       => ['uint']                    => 'uint'],
    ) {
        $ffi->attach([$_->[0] => '_ffi_' . $_->[0]] => @$_[1 .. $#$_]);
    }
}

sub new {
    my $proto = shift();
    my $file  = @_ % 2 ? shift() : undef;
    my %args  = @_;
    my $lps;

    $args{verbose} = VERBOSE_NORMAL unless (defined($args{verbose}));

    if ($file) {
        $lps = _ffi_read_LP($file, $args{verbose}, undef);

        return unless $lps;
    }
    else {
        $lps = _ffi_make_lp(0, 0);

        return unless $lps;

        _ffi_set_verbose($args{verbose});
    }

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

sub verbose {
    my ($self) = @_;

    if (@_ > 1) {
        _ffi_set_verbose($$self, $_[1]);
    }

    return _ffi_get_verbose($$self);
}


1;
