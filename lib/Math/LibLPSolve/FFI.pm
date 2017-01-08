package Math::LibLPSolve::FFI;

use strict;
use warnings;

use File::Spec::Functions qw(catdir);
use File::Temp qw(tempfile);
use FFI::CheckLib ();
use FFI::Platypus ();
use Scalar::Util qw(looks_like_number);

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
        [copy_lp           => ['uint']                    => 'uint'],
        [delete_lp         => ['uint']                    => 'void'],
        [get_Ncolumns      => ['uint']                    => 'int'],
        [get_Norig_columns => ['uint']                    => 'int'],
        [get_Norig_rows    => ['uint']                    => 'int'],
        [get_Nrows         => ['uint']                    => 'int'],
        [get_verbose       => ['uint']                    => 'int'],
        [is_debug          => ['uint']                    => 'char'],
        [is_trace          => ['uint']                    => 'char'],
        [make_lp           => ['int', 'int']              => 'uint'],
        [print_lp          => ['uint']                    => 'void'],
        [read_LP           => ['string', 'int', 'string'] => 'uint'],
        [resize_lp         => ['uint', 'int', 'int']      => 'unsigned char'],
        [set_debug         => ['uint', 'char']            => 'void'],
        [set_trace         => ['uint', 'char']            => 'void'],
        [set_verbose       => ['uint', 'int']             => 'void'],
        [solve             => ['uint']                    => 'uint'],
        [write_lp          => ['uint', 'string']          => 'unsigned char'],
    ) {
        $ffi->attach([$_->[0] => '_ffi_' . $_->[0]] => @$_[1 .. $#$_]);
    }
}

sub new {
    my $proto = shift();
    my %args  = @_;
    my $lps;

    $args{verbose} = VERBOSE_NORMAL unless (defined($args{verbose}));

    if (exists($args{model})) {
        my ($fh, $fn) = tempfile('lpXXXXXX', SUFFIX => '.lp', TMPDIR => 1, UNLINK => 1);

        binmode($fh, ':utf8');
        print($fh $args{model});

        $lps = _ffi_read_LP($fn, $args{verbose}, undef);

        unlink($args{file});

        return unless $lps;
    }
    elsif (exists($args{file})) {
        $lps = _ffi_read_LP('' . $args{file}, $args{verbose}, undef);

        return unless $lps;
    }
    else {
        for (qw(rows columns)) {
            $args{$_} = 0 unless exists($args{$_}) && looks_like_number($args{$_}) && $args{$_} >= 0;
            $args{$_} = int($args{$_});
        }

        $lps = _ffi_make_lp($args{rows}, $args{columns});

        return unless $lps;

        _ffi_set_verbose($lps, $args{verbose});
    }

    _ffi_set_debug($lps, 1) if $args{is_debug};
    _ffi_set_trace($lps, 1) if $args{is_trace};

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

sub dump {
    _ffi_print_lp(${$_[0]});
    return;
}

sub is_debug {
    my ($self) = @_;

    if (@_ > 1) {
        _ffi_set_debug($$self, !!$_[1]);
    }

    return unless defined(wantarray());
    return _ffi_is_debug($$self);
}

sub number_of_columns {
    return _ffi_get_Ncolumns(${$_[0]});
}

sub number_of_original_columns {
    return _ffi_get_Norig_columns(${$_[0]});
}

sub number_of_original_rows {
    return _ffi_get_Norig_rows(${$_[0]});
}

sub number_of_rows {
    return _ffi_get_Nrows(${$_[0]});
}

sub resize {
    my $self = shift();

    return 1 unless @_;

    my %args = @_;

    for (qw(rows columns)) {
        unless (exists($args{$_}) && looks_like_number($args{$_}) && $args{$_} >= 0) {
            no strict 'refs';
            $args{$_} = (my $meth = 'number_of_' . $_)->($self);
        }
        else {
            $args{$_} = int($args{$_});
        }
    }

    return _ffi_resize_lp($$self, $args{rows}, $args{columns});
}

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

    return unless defined(wantarray());
    return _ffi_get_verbose($$self);
}

sub write {
    my ($self) = @_;

    return _ffi_write_lp($$self, $_[1]);
}


1;
