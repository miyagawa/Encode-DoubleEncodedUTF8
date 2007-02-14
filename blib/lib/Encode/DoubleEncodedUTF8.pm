package Encode::DoubleEncodedUTF8;

use strict;
use base qw( Encode::Encoding );
use Encode 2.12 ();
our $VERSION = '0.01';

__PACKAGE__->Define('utf-8-de');

my $utf8_regexp = <<'.' ;
        [\x{00}-\x{7f}]
      | [\x{c2}-\x{df}][\x{80}-\x{bf}]
      |         \x{e0} [\x{a0}-\x{bf}][\x{80}-\x{bf}]
      | [\x{e1}-\x{ec}][\x{80}-\x{bf}][\x{80}-\x{bf}]
      |         \x{ed} [\x{80}-\x{9f}][\x{80}-\x{bf}]
      | [\x{ee}-\x{ef}][\x{80}-\x{bf}][\x{80}-\x{bf}]
      |         \x{f0} [\x{90}-\x{bf}][\x{80}-\x{bf}]
      | [\x{f1}-\x{f3}][\x{80}-\x{bf}][\x{80}-\x{bf}][\x{80}-\x{bf}]
      |         \x{f4} [\x{80}-\x{8f}][\x{80}-\x{bf}][\x{80}-\x{bf}]
.

my $re_bit = join "|", map { Encode::encode("utf-8",chr($_)) } (127..255);

sub decode {
    my ($obj, $buf, $chk) = @_;

    $buf =~ s{(($re_bit)+)}{ _check_utf8_bytes($1) }ego;
    $_[1] = '' if $chk; # this is what in-place edit means

    Encode::decode_utf8($buf);
}

sub _check_utf8_bytes {
    my $bytes = shift;

    my $possible_utf8 = Encode::encode("latin-1", Encode::decode("utf-8", $bytes));

    # see CAVEAT of perldoc Encode ... decode() doesn't keep the original bytes
    my $copy = $possible_utf8;
    eval { Encode::decode("utf-8-strict", $copy, Encode::FB_CROAK) };

    return $@ ? $bytes : $possible_utf8;
}

sub encode {
    use Carp;
    Carp::croak("utf-8-de doesn't support encode() ... Why do you want to do that?");
}

1;
__END__

=for stopwords utf-8 UTF-8

=head1 NAME

Encode::DoubleEncodedUTF8 - Fix double encoded UTF-8 bytes to the correct one

=head1 SYNOPSIS

  use Encode;
  use Encode::DoubleEncodedUTF8;

  my $string = "\x{5bae}";
  my $bytes  = encode_utf8("\x{5bae}");
  my $dodgy_utf8 = $string . $bytes; # $bytes is now double encoded

  my $fixed = decode("utf-8-de", $dodgy_utf8); # "\x{5bae}\x{5bae}"

=head1 DESCRIPTION

Encode::DoubleEncodedUTF8 adds a new encoding C<utf-8-de> and fixes
double encoded utf-8 bytes found in the original bytes to the correct
Unicode entity.

The double encoded utf-8 frequently happens when strings with UTF-8
flag and without are concatenated. See L<encoding::warnings> for
details.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<encoding::warnings>, L<Test::utf8>

=cut
