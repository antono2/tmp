module main

import some_module as sm

// NOTE: Build array.h as shared library
// gcc -c -fPIC include/array.c
// gcc -fPIC -shared array.o
#flag -L @VMODROOT
#flag -I @VMODROOT/include
#include "array.c"

pub type Array_t = C.array_t
@[typedef]
struct C.array_t {
pub mut:
	array_ptr  &&char
	array_len  int
	string_len int
}

pub type Struct_array = C.struct_array
@[typedef]
struct C.struct_array {
pub mut:
	arr [4]Array_t
	enu [2]sm.Flag_bits
}

enum Flag_bits_main {
	aaaa = 0
	bbbb = 1
	cccc = 2
}

pub type Flags = u32

pub type Union_t = C.union_t
@[typedef]
pub union C.union_t {
pub mut:
	float32 [4]f32
	int32   [4]i32
	uint32  [4]u32
}


fn C.get_string_array() &&char
@[inline]
pub fn get_string_array() &&char {
	return C.get_string_array()
}

pub type PFN_get_struct_array = fn() Struct_array
fn C.get_struct_array() Struct_array
@[inline]
pub fn get_struct_array() Struct_array {
	return C.get_struct_array()
}

pub type PFN_get_enum = fn() Flags
fn C.get_enum() Flags
@[inline]
pub fn get_enum() Flags {
	return C.get_enum()
}

fn C.get_union() Union_t

@[inline]
pub fn get_union() Union_t {
	return C.get_union()
}

@[keep_args_alive]
fn C.get_stub_main([2]Flag_bits_main)

pub type PFN_get_stub_main = fn ([2]Flag_bits_main)

@[inline]
pub fn get_stub_main(param [2]Flag_bits_main) {
	C.get_stub_main(param)
}

// @[keep_args_alive]
// fn C.set_struct_array(C.struct_array)
// pub type PFN_set_struct_array = fn (C.struct_array)
// @[inline]
// pub fn set_struct_array(param C.struct_array) {
//   C.set_struct_array(param) 
// }

@[keep_args_alive]
fn C.set_struct_array(&Struct_array)
pub type PFN_set_struct_array = fn (&Struct_array)
@[inline]
pub fn set_struct_array(param &Struct_array) {
  C.set_struct_array(param) 
}


fn main() {
	string_array := get_string_array()
	struct_array := get_struct_array()
	flags := get_enum()
	union_t := get_union()
	println(unsafe { string_array[3].vstring() })
	println(unsafe { struct_array.arr[3].array_ptr.vstring() })
	println(unsafe { sm.Flag_bits(struct_array.enu[1]) })
	println(unsafe { sm.Flag_bits(flags) })
	println('union_t size: ${sizeof(union_t)} type: ${typeof(union_t).name}')
	union_t_value := unsafe { union_t.uint32[0] }
	println('union_t value: ${union_t_value}')

	sm.get_stub([2]sm.Flag_bits{init: sm.Flag_bits.bbb})

	get_stub_main([2]Flag_bits_main{init: Flag_bits_main.bbbb})

	set_struct_array(&struct_array)
}
