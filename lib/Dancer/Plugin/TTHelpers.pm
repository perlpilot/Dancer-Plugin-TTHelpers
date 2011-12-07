package Dancer::Plugin::TTHelpers;
# ABSTRACT: Useful routines for generating HTML for use with Dancer + TT

use strict; use warnings;
use 5.10.0;
use Dancer ':syntax';
use Try::Tiny;

sub make_attribute_string {
    return defined $_[0] 
         ? join " ", map { $_ . '="' . $_[0]->{$_} . '"' } keys %{$_[0]}
         : "";
}

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
    my $idx = try { $obj->can('id') && "[" . ($obj->id // "") . "]" } catch { "[]" };
    return $idx;
}

hook 'before_template' => sub {
    my $tokens = shift;

    $tokens->{css} = sub {
        my $attributes = &process_attributes;
        my ( $uri, $ie_cond ) = @_;
        $uri .= '.css' unless $uri =~ /\.css$/;
        return
            ($ie_cond ? "<!--[if $ie_cond]>" : '')
          . qq(<link rel='stylesheet' href=')
          . request->uri_base . "/css/$uri"
          . qq(' type='text/css' $attributes />)
          . ($ie_cond ? "<![endif]-->" : '');
    };

    $tokens->{js} = sub {
        my ( $uri, $ie_cond ) = @_;
        $uri .= '.js' unless $uri =~ /\.js$/;
        return
            ($ie_cond ? "<!--[if $ie_cond]>" : '')
          . qq(<script languages='javascript' src=')
          . request->uri_base . "/js/$uri"
          . qq(' type='text/javascript'></script>)
          . ($ie_cond ? "<![endif]-->" : '');
    };

    $tokens->{radio} = sub {
        my $attributes = &process_attributes;
        my ($obj, $name, $values, $sep) = @_;
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
    };

    $tokens->{text} = sub {
        my $attributes = &process_attributes;
        my ($obj, $name, $value) = @_;
        my $idx = compute_idx($obj);
        my $val = do { try { $obj->$name } } // $value // "";
        return qq(<input type="text" name="$name$idx" value="$val" $attributes />);
    };

    $tokens->{select} = sub {
        my $attributes = &process_attributes;
        my ($obj, $name, $options, $key, $value) = @_;
        my $idx = compute_idx($obj);
        my $str = $name ? qq(<select name="$name$idx" $attributes>) : "<select>";
        my $on = $obj && $name ? ($obj->$name // "") : "";
        for my $o (@$options) {
            my ($disp, $val);
            if ($key && $value) {
                $disp = do { try { $o->$value } catch { $o->{$value} } } // "";
                $val  = do { try { $o->$key } catch { $o->{$key} } } // "";
            } else {
                $disp = $val = $o;
            }
            my $selected = $on eq $val ? " selected" : "";
            $str .= qq(<option value="$val"$selected>$disp</option>);
        }
        $str .= "</select>";
        return $str;
    };

    $tokens->{button} = sub {
        my ($value, $attrs) = @_;
        my $attributes = make_attribute_string($attrs);
        return qq(<input type="button" value="$value" $attributes />);
    };

    $tokens->{hidden} = sub {
        my ($obj,$name,$value, $attrs) = @_;
        my $idx = compute_idx($obj);
        my $attributes = make_attribute_string($attrs);
        return qq(<input type="hidden" name="$name$idx" value="$value" $attributes />);
    };

    $tokens->{checkbox} = sub {
        my ($obj, $name, $checked, $attrs) = @_;
        my $idx = compute_idx($obj);
        my $attributes = make_attribute_string($attrs);
        $checked = try { $obj->$name } catch { $checked // 1 };
        $attributes .= " checked" if $checked;
        return qq(<input type="checkbox" name="$name$idx" value="1" $attributes />);
    };

};


1;
