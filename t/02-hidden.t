#!/usr/bin/env perl

use 5.10.0;
use Test::More tests => 4;
use Dancer::Plugin::TTHelpers;
use Test::XPath;

{
    my $generated = Dancer::Plugin::TTHelpers::hidden('foo','bar');
    my $tx = Test::XPath->new( xml => $generated, is_html => 1 );

    $tx->ok('//input', "Has input tag");
    $tx->ok('//input[@type="hidden"]', "\ttype = hidden");
    $tx->ok('//input[@name="foo"]', "\tname = foo");
    $tx->ok('//input[@value="bar"]', "\tvalue = bar");
}
