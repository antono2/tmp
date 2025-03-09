#!/usr/bin/perl

#### Last comment causes issue with v fmt
#### Example
# // Obsoleted in 1.90.0: Use ImGuiChildFlags_AlwaysUseWindowPadding in BeginChild() call.
# // #ifndef IMGUI_DISABLE_OBSOLETE_FUNCTIONS
# }
#### Or could be just const on root level: const ( = 3 ) with no name

#### Empty name without corresponding member in dcimgui.h
#### Example
# // Descending = 9->0, Z->A etc.
#	 = 3
#### gets removed
####

#### Remove im_gui_ in all strings
#### Example
# fn im_gui_end_popup()
# ->
# fn end_popup()
####

#### Remove struct/enum member names substring where it matches the struct/enum name
#### Example
# // Note: windows with the ImGuiWindowFlags_NoInputs flag are ignored by IsWindowHovered() calls.
# enum ImGuiHoveredFlags_ {
#   hovered_flags_none = 0
#   // Return true if directly over the item/window, not obstructed by another window, not obstructed by an active popup or modal blocking inputs under them.
#   hovered_flags_child_windows = 1 << 0
# ->
# // Note: windows with the ImGuiWindowFlags_NoInputs flag are ignored by IsWindowHovered() calls.
# enum ImGuiHoveredFlags_ {
#   none = 0
#   // Return true if directly over the item/window, not obstructed by another window, not obstructed by an active popup or modal blocking inputs under them.
#   child_windows = 1 << 0
####

#### Alias to base type
#### Example
# // 8-bit signed integer
# type ImU8 = u8
# type ImGuiSortDirection = ImU8
# ->
# type ImGuiSortDirection = u8
####

#### Trim tailing _t in struct names
#### Example
# ImFontAtlas_t {
# ->
# struct ImFontAtlas {
####

#### Store all struct names and replace unknowns with C.name
#### Example
# ImGuiContext is not in struct names array but used in function
# fn destroy_context(ctx &ImGuiContext)
# ->
# pub type C.ImGuiContext = voidptr
# fn destroy_context(ctx &C.ImGuiContext)
####

use strict;
use warnings;

my $file_in             = 'src/imgui.v';
my $file_out            = 'src/imgui_new.v';
my $dcimgui_header_file = 'imgui/dcimgui.h'
  ;    # Only available after generate_imgui_v.sh ran at least once

# Find version in dcimgui.h and put it right behind "module imgui\n"
open my $in, '<', $dcimgui_header_file
  or die "Can't read ${dcimgui_header_file}: $!";
my $dcimgui_header = do { local $/; <$in> };    # slurp!
close($in);

$dcimgui_header =~ qr/^#define\sIMGUI_VERSION\s+"([[:print:]]+)"$/m;
my $version_str = $1;
$dcimgui_header =~ qr/^#define\sIMGUI_VERSION_NUM\s+([[:print:]]+)$/m;
my $version_num = $1;

my $version_v = "";
if ( length $version_str ) {
  $version_v = "pub const version = '" . $version_str . "'\n";
  if ( length $version_num and $version_num ne $version_str ) {
    $version_v = $version_v . "pub const version_num = " . $version_num . "\n";
  }
}
my $module_v =
    "\nmodule imgui\n"
  . "#flag -I \@VMODROOT/imgui\n#include <dcimgui.h>\n"
  . $version_v;

# 1d array % 2 to get tuple behavior
# General cleanup substitutes
my @r = (
  qr/\/\/[[:print:]]+[\s=]+\d+$/,
  "", qr/\n\s+\=\s[0-9]/, "", qr/(\sim_gui_)(?=\w+)/, " ",
  qr/\nmodule main\n/, $module_v
);

open my $in, '<', $file_in or die "Can't read ${file_in}: $!";
my $content = do { local $/; <$in> };    # slurp!
close($in);

#### Basic Cleanup
my $cur_regex;
for my $i ( 0 .. $#r ) {
  if ( $i % 2 == 0 ) {
    $cur_regex = $r[$i];
    next;
  }
  $content =~ s/$cur_regex/$r[$i]/gsm;
}

####
#### Alias to base type
####
my $alias_name_regex =
qr/type\s(\w+)\s=\s(bool|u8|i8|u16|i16|u32|i32|u64|i64|int|f32|f64|voidptr|usize|isize)\n/;

# Hash map of name, type
my %name_type_map;
my @alias_dedup;
my $alias_names_regex_group = "(";
while ( $content =~ /$alias_name_regex/g ) {
  my $cur_name = $1;
  if ( defined $name_type_map{$cur_name} ) {
    next;
  }
  $name_type_map{$cur_name} = $2;
  $alias_names_regex_group = $alias_names_regex_group . $cur_name . "|";
}

# Replace last | with )
#print "################ alias names regex group PRE START #############\n";
#print $alias_names_regex_group;
#print "################ alias names regex group PRE END #############\n";
$alias_names_regex_group =~ s/\|$/\)/;

#print "################ alias names regex group START #############\n";
#print $alias_names_regex_group;
#print "################ alias names regex group END #############\n";
if ( $alias_names_regex_group ne "()" ) {

  # Get 3 groups, concat them back together,
  # with type alias replaced by $name_type_map
  my $search_replace_regex =
    qr/(type\s\w+\s=\s)\Q$alias_names_regex_group\E(\n)/;
  while ( $content =~ /$search_replace_regex/s ) {

    # Assuming there is always a map to the base type
    $content =~ s/$search_replace_regex/$1$name_type_map{$2}$3/;
  }
}

#use Data::Dumper;
#print Dumper(\%name_type_map);

####
#### Trim tailing _t in struct names
####
my $struct_name_regex = qr/(struct\s\w+)(_t)(\s\{)/;
$content =~ s/$struct_name_regex/$1$3/g;

####
#### Store all struct names & type def names and replace unknowns with C.name
####
my @struct_names = $content =~ /\bstruct\s(\w+)\s\{/g;

#print "################ struct names START #############\n";
#print @struct_names;
#print "################ struct names END #############\n";

my @typedef_names = $content =~ /\btype\s(\w+)\s=\s/g;

#print "################ typedef names START #############\n";
#print @typedef_names;
#print "################ typedef names END #############\n";

# Find function parameter types
# Using a map to deduplicate
my %func_param_types;
my %struct_member_types;

# All function parameter types and return types.
my @func_param_content = $content =~ /(?:[^\/]fn\s\w+\()(.*)/gc;
print pos $content;
#my @func_param_content = $content =~ /(?:(?:\w+\s(?!fn)(?:&?)*)\s?(\w+))/gc;

# Also get the callback function defintions
push @func_param_content, $content =~ /(?:[^\/]fn\s\().*/gc;

#print "START Func Param Content ####\n";
#use Data::Dumper;
#print Dumper(\@func_param_content);
#print "END Func Param Content ####\n";
foreach my $func_params (@func_param_content) {
  if ( $func_params =~ /\)\s(?:&?)*(\w+)/gc ) {
    @func_param_types{$1} = 1;
  }

  # Remove end, starting from )
  $func_params =~ s/\).*//;

  if ( $func_params eq "" ) { next; }
  my @params = split( ",", $func_params );
  foreach my $param (@params) {
    #print "$param processing single func param\n";

    #$param =~ /(?:\w+\s(?:&?)*)(\w+)(?{ @func_param_types{$1} = 1 })/gc;
    foreach ( $param =~ /(?:\w+\s(?:&?)*)(\w+)/gc ) {
      if ( $1 eq "fn" ) { next; } # Didn't manage to filter out "fn" in regex
      @func_param_types{$1} = 1;
    }
  }
}

# Do the same for struct member types, like &ImFontBuilderIO in struct ImFontAtlas {
my @struct_scope_content =
  $content =~ /(?:struct\s\w+\s\{((?:[[:print:]\s][^\}])+)\})/g;

use Data::Dumper;
print Dumper(\@struct_scope_content);
print "\n";
foreach my $struct_content (@struct_scope_content) {
  my @lines = split( "\n", $struct_content );
  foreach my $line (@lines) {
    if ($line =~ /\/\//) {next;}
    print "$line processing single struct member\n";
    $line =~ /[^\/]\s+\w+\s(?:&?)*(\w+)(?{ @struct_member_types{$1} = 1 })/;
  }
}

# Find match and add it as key into func_param_types map, which deduplicates automatically
#while ( $content =~ /$func_param_regex(?{ @func_param_types{$^N} = 1 })/gc ) {
#}    #/gc = global matches and continue at last successful pos
print join( ", ", ( keys %func_param_types ) );
print "\n^^^ func_param_types \n struct_member_types:\n";
print join( ", ", ( keys %struct_member_types ) );

my @basetypes = (
  "bool",    "u8",    "i8",  "u16", "i16", "u32",
  "i32",     "u64",   "i64", "int", "f32", "f64",
  "voidptr", "usize", "isize"
);

my $needs_c_prefix_search = "(";
my @needs_c_prefix_array;

# Find types need as parameter in some function defintion
# or in a struct, where no local definition was found
foreach my $param_type ( keys %func_param_types ) {
  if (  not( "@basetypes" =~ /\b\Q$param_type\E\b/ )
    and not( "@struct_names"  =~ /\b\Q$param_type\E\b/ )
    and not( "@typedef_names" =~ /\b\Q$param_type\E\b/ )
    and not( exists $name_type_map{$param_type} ) )
  {
    print $param_type . "\n";
    $needs_c_prefix_search = $needs_c_prefix_search . $param_type . "|";
    push @needs_c_prefix_array, $param_type;
  }
}
foreach my $param_type ( keys %struct_member_types ) {
  if (  not( "@basetypes" =~ /\b\Q$param_type\E\b/ )
    and not( "@struct_names"  =~ /\b\Q$param_type\E\b/ )
    and not( "@typedef_names" =~ /\b\Q$param_type\E\b/ )
    and not( exists $name_type_map{$param_type} ) )
  {
    print $param_type . "\n";
    $needs_c_prefix_search = $needs_c_prefix_search . $param_type . "|";
    push @needs_c_prefix_array, $param_type;
  }
}

# Replace last | with )
$needs_c_prefix_search =~ s/\|$/\)/;

print "################ needs c prefix START #############\n";
print $needs_c_prefix_search;
print "################ needs c prefix END #############\n";

# Unmatched ( in regex; marked by <-- HERE in m/(?<!(&?)C\.)\b&?( <-- HERE ...
# Should be an issue with needs_c_prefix_search. Something went wrong at collecting types in func_param_types or struct_member_types
my $set_c_prefix = qr/\b$needs_c_prefix_search\b/;
$content =~ s/$set_c_prefix/C\.$1/g;

# Add 'pub type C.SomeType = voidptr;' anywhere
my $old_module_v = $module_v;
for my $c_type (@needs_c_prefix_array) {
  print "Found " . $c_type . " in need of C. type definition.\n";
  $module_v .= "\npub type C." . $c_type . " = voidptr";
}

# Append callback function definitions
# // Callback and functions types
# typedef int (*ImGuiInputTextCallback)(ImGuiInputTextCallbackData* data);  // Callback function for ImGui::InputText()
# typedef void (*ImGuiSizeCallback)(ImGuiSizeCallbackData* data);           // Callback function for ImGui::SetNextWindowSizeConstraints()
# typedef void* (*ImGuiMemAllocFunc)(size_t sz, void* user_data);           // Function signature for ImGui::SetAllocatorFunctions()
# typedef void (*ImGuiMemFreeFunc)(void* ptr, void* user_data);             // Function signature for ImGui::SetAllocatorFunctions()
# Get them from dcimgui.h and translate automatically, at some later time, maybe
$module_v .=
"\n\npub type ImGuiInputTextCallback = fn(data &ImGuiInputTextCallbackData) int"
  . "\npub type ImGuiSizeCallback = fn(data &ImGuiSizeCallbackData)"
  . "\npub type ImGuiMemAllocFunc = fn(sz usize, user_data voidptr) voidptr"
  . "\npub type ImGuiMemFreeFunc = fn(ptr voidptr, user_data voidptr)";

$content =~ s/\Q$old_module_v\E/$module_v/g;

#### Replace enum member values, where | bit operator is found
#### and replace operands with their numerical values
#### Example
#	window_flags_no_nav_inputs = 1 << 16
#	window_flags_no_nav_focus = 1 << 17
#	window_flags_no_nav        = window_flags_no_nav_inputs | window_flags_no_nav_focus
# ->
#	window_flags_no_nav_inputs = 1 << 16
#	window_flags_no_nav_focus = 1 << 17
#	window_flags_no_nav        = 1 << 16 | 1 << 17
####

# Prepare enum_name_scope_string_map, which stores the string inside an enum scope { ... } by enum name
my %enum_name_scope_string_map;

sub update_enum_name_scope_string_map {
  %enum_name_scope_string_map = ();
  while (
    $content =~

#/enum\s(\w+)\s\{([^\}]*(?:\s=\s[^A-Z]+)[^\}]?)(?{ $enum_name_scope_string_map{$1}=$2 })\}/gc
/enum\s(\w+)\s\{([^\}]*(?:\s=\s(?:[^A-Z]+|0x[0-9ABCDEF]+)))\}(?{ $enum_name_scope_string_map{$1} = $2 })/gc
    )
  {
  }
}
update_enum_name_scope_string_map();

#use Data::Dumper;
#print Dumper(\%enum_name_scope_string_map);

# abc = aaa | bbb | ccc
# Using map to dedup enum names and store the member name and the exact search string to replace later in an array
# It's assumed that inside each enum scope, the members with base values alwas come before each use
my $get_enum_base_value_first_run = 1;
my %enum_member_name_value;

sub get_enum_base_value {
  my $enum_name   = @_[0];
  my $member_name = @_[1];
  if ($get_enum_base_value_first_run) {
    $get_enum_base_value_first_run = 0;

    # Map each each enum name (key) to each of its members [name, value]
    # Scan each member for its value, but only when they are not an alias
    foreach my $enum_scope_name ( keys %enum_name_scope_string_map ) {

     # Append each name&value to enum_member_name_value, where it's a base value
      my @lines = split( '\n', %enum_name_scope_string_map{$enum_scope_name} );
      foreach my $line (@lines) {
        $line =~
/[^\/]([a-z0-9_]+)\s=\s([0-9\s<\|xABCDEF]+)(?{ push @{$enum_member_name_value{$enum_scope_name}}, ($1, $2) })/gc;
      }
    }
    use Data::Dumper;
    print Dumper( \%enum_member_name_value );
  }

  if ( exists $enum_name_scope_string_map{$enum_name} ) {
    my @names_values_arr = @{ $enum_member_name_value{$enum_name} };
    my $cur_name;

    for my $i ( 0 .. $#names_values_arr ) {
      if ( $i % 2 == 0 ) {
        $cur_name = $names_values_arr[$i];
        next;
      }

      #print "### Checking for $cur_name in @names_values_arr" ;
      if ( $cur_name eq $member_name ) {

        #print "exists: name: "
        #  . $enum_name
        #  . " member: "
        #  . $member_name
        #  . " ret: "
        #  . $names_values_arr[$i] . "\n";
        return $names_values_arr[$i];
      }
    }
  }
  else {
    print
"$enum_name not found in enum_name_scope_string_map. Make sure to reset get_enum_base_value_first_run to 1 after each iteration, to fetch the translated base values.";
  }
  print "RETURNING EMPTY base_value for enum: "
    . $enum_name
    . " member: "
    . $member_name . "\n";

# RETURNING EMPTY member value. enum: im_draw_flags_round_corners_all member: im_draw_flags_round_corners_top_left |
# This should not happen, as all base values should be set in the same enum scope and above the current
  return "";
}    # sub

# Alias_to_base_value is called recursively
# value_map should not reset on another run
my %value_map;
my $max_alias_to_base_value_runs    = 10;
my $alias_to_base_value_run_counter = 0;

sub alias_to_base_value {
  for my $enum_name ( keys %enum_name_scope_string_map ) {
    my $enum_scope_content = $enum_name_scope_string_map{$enum_name};
    my @lines              = split( "\n", $enum_scope_content );
    foreach my $line (@lines) {
      if ( $line =~ /\/\// ) { next; }

      #my $to_translate; # /(?:[\s\|0-9<]+)\b([^0-9][a-z0-9_]+\s)[^=]/g
      while ( $line =~ /(?:[\s\|0-9<]+)(?:=\s|\|\s)([^0-9][a-z0-9_]+)/g ) {
        my $alias = $1;

        #print "##ALIAS " . $alias . "\n";
        if (
          not( my $base_value = get_enum_base_value( $enum_name, $alias ) ) ==
          "" )
        {
          print "PRE " . $line . "\n";
          my $orig = $line;
          $line =~ s/\Q$alias\E/$base_value/;
          print "POST " . $line . "\n";
          $enum_scope_content =~ s/\Q$orig\E/$line/;
        }
      }

    }    # foreach
         #print "####\n" . $enum_scope_content . "####\n";

    # Apply translated enum member values to base value
    $content =~
      s/\Q$enum_name_scope_string_map{$enum_name}\E/$enum_scope_content/;

    #print "\n####" . $enum_scope_content . "####\n";

  }    # for

  # Recursively run again to cover multiple aliasing levels
  # To avoid stack overflow, just stop after some set number of levels,
  $alias_to_base_value_run_counter += 1;
  if ( not( $alias_to_base_value_run_counter >= $max_alias_to_base_value_runs )
    and $content =~ /enum\s\w+\s\{[^\}]*(?:[a-z0-9_]+\s=|\|\s[a-z0-9_]+)/ )
  {
    # Make sure to update and clear for the next run
    update_enum_name_scope_string_map();

# Note: In case this is not reset, a missing enum member in enum_member_name_value will cause $content not to be updated.
# I write this note in hopes, that nobody will ever have to hunt for silent errors ever again.
    $get_enum_base_value_first_run = 1;
    %enum_member_name_value        = ();
    alias_to_base_value();
  }
  else {
    print "Enum alias to base value translations done. Runs: "
      . $alias_to_base_value_run_counter . "\n";
  }
}    # sub

alias_to_base_value();

####
#### Write out result to file
####
open my $out, '>', $file_out or die "Can't write ${file_out}: $!";
print $out $content;
close($out);

