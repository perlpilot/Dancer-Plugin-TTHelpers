package Dancer::Plugin::TTHelpers;
# ABSTRACT: Useful routines for generating HTML for use with Dancer + TT

=head1 SYNOPSIS

In your Dancer application's MyApp.pm file ...

    package MyApp;
    use Dancer ':syntax';
    use Dancer::Plugin::TTHelpers;

and in your application's views ...

    <!-- in layout.tt -->
    <% css('foo') %>
    <% js('bar') %>

    <!-- in index.tt -->
    Name: <% text('name') %></br>
    Shirt Size: <% radio('size', sizes) %></br>
    Quantity: <% select('quantity', quants) %></br>
    <!-- etc. -->

=head1 DESCRIPTION

B<NOTE>: this module is very alpha code.  I<Use at your own risk>

=head2 Background

I was working on a Dancer app and got tired of using the normal Template
Toolkit mechanisms for generating forms.  Also, I got tired of writing
the boiler-plate for CSS and Javascript.  Then I remembered when I
was working with Rails a few years ago, there were some handy
routines for generating this stuff, so after looking around briefly
for something similar to what I wanted, I decided to make my own.

This was the result.

=head2 The Helpers

By using this module in your Dancer app, new routines are made available from
within your views that aid in generating HTML for forms and the standard HTML
required for include CSS or Javascript files.

Following are the list of routines available from within your templates.
Items within square brackets(C< [ ] >) are optional and may be omitted:

=over

=item C<css(FILE, [ IE_COND ], [ ATTR ])>

Outputs a C<< <link> >> tag.  C<FILE> should be the name of a CSS
file within the F<public/css> directory of your app.  If C<FILE> does not 
end with C<.css>, then it is appended.  If COND is specified, the CSS link is
surrounded with appropriate comments for IE.  Any additional attributes for the
C<< <link> >> tag may be specified as a hashref.

Example usage:

    <% css('print', { media => "print" }) %>
    <% css('ie', 'lt IE 8' { media => "screen,projection" }) %>

which could result in the following output:

    <link rel='stylesheet' href='http://localhost:3000/css/print.css' type='text/css' media="print" />
<!--[if lt IE 8]><link rel='stylesheet' href='http://localhost:3000/css/ie.css' type='text/css' media="screen,projection" /><![endif]-->

=item C<js(FILE, [ IE_COND ], [ ATTR ])>

Outputs a C<< <script> >> tag with appropriate C<language> and C<type>
attributes for javascript.  C<FILE> should be the name of a javascript file
located within F<public/javascripts>.  If C<FILE> does not end with C<.js>,
then it is appended.  If COND is specified, the CSS link is surrounded 
with appropriate comments for IE.  Any additional attributes for the
C<< <script> >> tag may be specified as a hashref.

Example usage:

    <% js('jquery') %>

which could result in the following output:

    <script languages='javascript' src='http://localhost:3000/js/jquery.js' type='text/javascript'></script>

=back

The rest of the helpers are for generating form elements.  Each one may optionally pass an
object as its first argument.  It is expected that this object will have an accessor with
the same name as the one specified as the second argument so that the form elements can be
initialized with the object's values by default.

=over

=item C<radio([OBJ], NAME, [VALUES], [SEPARATOR])>

Examples:

    <% radio('item', [ 'hat', 'shirt', 'shorts' ]) %>
    <% radio(obj, 'size', [ 'small', 'medium', 'large' ]) %>

=item C<text([OBJ], NAME, VALUE, [ ATTR ])>


Examples:

    <% text('title') %>
    <% text(person, 'name') %>
    <% text(person, 'dob', { size => 8 }) %>

=item C<select([OBJ], NAME, OPTIONS, [KEY], [VALUE], [ ATTR ])>

Example:

    <% select('priority', [ 'low','medium','high' ]) %>

=item C<checkbox([OBJ], NAME, CHECKED, [ ATTR ])>

Example:

=item C<button([OBJ], NAME, [VALUE], [ ATTR ])>


Example:

=item C<hidden([OBJ], NAME, VALUE, [ ATTR ] )>


Example:

=back

=cut

use strict; use warnings;
use 5.10.0;
use Dancer ':syntax';
use Try::Tiny;
use Scalar::Util qw/ blessed /;

hook 'before_template' => sub {
    my $tokens = shift;

    $tokens->{css} = \&css;
    $tokens->{js} = \&js;
    $tokens->{radio} = \&radio;
    $tokens->{text} = \&text;
    $tokens->{select} = \&select;
    $tokens->{button} = \&button;
    $tokens->{checkbox} = \&checkbox;
    $tokens->{hidden} = \&hidden;
};

sub make_attribute_string {
    return defined $_[0] 
         ? join " ", map { $_ . '="' . $_[0]->{$_} . '"' } keys %{$_[0]}
         : "";
}

# NOTE: The first hashref we come across is assumed to be the 
#       attributes
sub process_attributes {
    for my $i (0..$#_) {
        if (ref $_[$i] eq 'HASH') {
            my $attrs = splice @_, $i, 1;
            return make_attribute_string($attrs);
        }
    }
    return "";
}

sub compute_idx {
    my $obj = shift;
    my $idx = try { $obj->can('id') && "[" . ($obj->id // "") . "]" } catch { "" };
    return $idx;
}

sub js {
    my $attributes = &process_attributes;
    my ( $uri, $ie_cond ) = @_;
    $uri .= '.css' unless $uri =~ /\.css$/;
    return
        ($ie_cond ? "<!--[if $ie_cond]>" : '')
      . qq(<link rel='stylesheet' href=')
      . request->uri_base . "/css/$uri"
      . qq(' type='text/css' $attributes />)
      . ($ie_cond ? "<![endif]-->" : '');
}

sub css {
    my ( $uri, $ie_cond ) = @_;
    $uri .= '.js' unless $uri =~ /\.js$/;
    return
        ($ie_cond ? "<!--[if $ie_cond]>" : '')
      . qq(<script languages='javascript' src=')
      . request->uri_base . "/js/$uri"
      . qq(' type='text/javascript'></script>)
      . ($ie_cond ? "<![endif]-->" : '');
}


sub radio {
    my $obj = shift if blessed $_[0];
    my $attributes = &process_attributes;
    my ($name, $values, $sep) = @_;
    $sep ||= '';
    my ($i, @ret) = 0;
    my $on = do { try { $obj->$name }  } // @{$values}[0];
    my $idx = compute_idx($obj);
    while ($i < @$values) { 
        my ($val,$disp) = @{$values}[$i, $i+1];
        my $checked = $on eq $val ? 'checked="checked"' : "";
        push @ret, qq(<input type="radio" name="$name$idx" value="$val" $checked $attributes />$disp);
    } continue { $i+=2 }
    return ref $sep eq 'ARRAY' ? @ret : join $sep,@ret;
}


sub text {
    my $obj = shift if blessed $_[0];
    my $attributes = &process_attributes;
    my ($name, $value) = @_;
    my $idx = compute_idx($obj);
    my $val = do { try { $obj->$name } } // $value // "";
    return qq(<input type="text" name="$name$idx" value="$val" $attributes />);
}


sub select {
    my $obj = shift if blessed $_[0];
    my $attributes = &process_attributes;
    my ($name, $options, $key, $value) = @_;
    my $idx = compute_idx($obj);
    my $str = $name ? qq(<select name="$name$idx" $attributes>) : "<select>";
    my $on = $obj && $name ? ($obj->$name // "") : "";
    for my $o (@$options) {
        my ($k, $v);
        if (ref $o eq 'HASH') {
            ($k,$v) = each %$o;
        } elsif ($key && $value) {
            $k  = do { try { $o->$key } catch { $o->{$key} } } // "";
            $v = do { try { $o->$value } catch { $o->{$value} } } // "";
        } else {
            $k = $v = $o;
        }
        $str .= qq(<option value="$k") . ($on eq $k ? " selected" : "") . qq(>$v</option>);
    }
    $str .= "</select>";
    return $str;
}


sub button {
    my $obj = shift if blessed $_[0];
    my $attributes = &process_attributes;
    my ($name, $value) = @_;
    $value //= $name;
    return qq(<input type="button" name="$name" value="$value" $attributes />);
}

sub hidden {
    my $obj = shift if blessed $_[0];
    my $attributes = &process_attributes;
    my ($name, $value) = @_;
    my $idx = compute_idx($obj);
    return qq(<input type="hidden" name="$name$idx" value="$value" $attributes />);
}


sub checkbox {
    my $obj = shift if blessed $_[0];
    my $attributes = &process_attributes;
    my ($name, $checked) = @_;
    my $idx = compute_idx($obj);
    $checked = try { $obj->$name } catch { $checked // 1 };
    $attributes .= " checked" if $checked;
    return qq(<input type="checkbox" name="$name$idx" value="1" $attributes />);
}

1;
