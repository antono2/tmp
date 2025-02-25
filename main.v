module main

import some_module as sm
import dl
import dl.loader
import v.vmod
// NOTE: Build array.c as shared library
// gcc -c -fPIC include/array.c
// gcc -fPIC -shared array.o

//#flag -L @VMODROOT
//#flag -I @VMODROOT/include
//#include "array.c"

struct Array_t {
pub mut:
	array_ptr  &&char
	array_len  int
	string_len int
}

struct ArrayStruct {
pub mut:
	arr [4]Array_t
	enu [2]sm.Flag_bits
}

enum Flag_bits_main {
	aaaa     = 0
	bbbb     = 1
	cccc     = 2
	max_enum = max_int
}

pub type Flags = u32

pub union Union_t {
pub mut:
	float32 [4]f32
	int32   [4]i32
	uint32  [4]u32
}

pub type PFN_get_string_array = fn () &&char

fn C.get_string_array() &&char
@[inline]
pub fn get_string_array() &&char {
	f := PFN_get_string_array((*p_loader).get_sym('get_string_array') or {
		println("Could not load symbol for 'get_string_array': ${err}")
		return &&char(0)
	})
	return f()
}

pub type PFN_get_array_struct = fn () ArrayStruct

fn C.get_array_struct() ArrayStruct
@[inline]
pub fn get_array_struct() ArrayStruct {
	f := PFN_get_array_struct((*p_loader).get_sym('get_array_struct') or {
		println("Could not load symbol for 'get_array_struct': ${err}")
		return ArrayStruct{}
	})
	return f()
}

pub type PFN_get_enum = fn () Flags

fn C.get_enum() Flags
@[inline]
pub fn get_enum() Flags {
	f := PFN_get_enum((*p_loader).get_sym('get_enum') or {
		println("Could not load symbol for 'get_enum': ${err}")
		return max_int
	})
	return f()
}

pub type PFN_get_union = fn () Union_t

fn C.get_union() Union_t

@[inline]
pub fn get_union() Union_t {
	f := PFN_get_union((*p_loader).get_sym('get_union') or {
		println("Could not load symbol for 'get_union': ${err}")
		return Union_t{}
	})
	return f()
}

@[keep_args_alive]
fn C.get_stub_main([2]Flag_bits_main)

pub type PFN_get_stub_main = fn ([2]Flag_bits_main)

@[inline]
pub fn get_stub_main(param [2]Flag_bits_main) {
	f := PFN_get_stub_main((*p_loader).get_sym('get_stub_main') or {
		println("Could not load symbol for 'get_stub_main': ${err}")
		return
	})
	f(param)
}

// const get_lib_names_from_vmod := fn [str_arr []string]{
// 	mut ret := []string{}
// 	for str in str_arr {
// 		ret << str.trim_space().trim(',')
// 	}
// 	return ret
// }

// pub const path_to_libdir = @env('PATH_TO_LIBDIR')
const loader_instance = *loader.get_or_create_dynamic_lib_loader(loader.DynamicLibLoaderConfig{
	flags:    dl.rtld_lazy
	key:      'my_key'
	env_path: $env('PATH_TO_LIBDIR') // LD_LIBRARY_PATH environment variable is searched by default
	paths:    [
		vmod.decode(@VMOD_FILE) or { vmod.Manifest{} }.unknown['lib_filenames'] or {
			[
				'CAN_NOT_BE_EMPTY_STRING',
			]
		}[0].split(',')[0] or { 'CAN_NOT_BE_EMPTY_STRING' }.trim_space(),
		vmod.decode(@VMOD_FILE) or { vmod.Manifest{} }.unknown['lib_filenames'] or {
			[
				'CAN_NOT_BE_EMPTY_STRING',
			]
		}[0].split(',')[1] or { 'CAN_NOT_BE_EMPTY_STRING' }.trim_space(),
		vmod.decode(@VMOD_FILE) or { vmod.Manifest{} }.unknown['lib_filenames'] or {
			[
				'CAN_NOT_BE_EMPTY_STRING',
			]
		}[0].split(',')[2] or { 'CAN_NOT_BE_EMPTY_STRING' }.trim_space(),
		vmod.decode(@VMOD_FILE) or { vmod.Manifest{} }.unknown['lib_filenames'] or {
			[
				'CAN_NOT_BE_EMPTY_STRING',
			]
		}[0].split(',')[3] or { 'CAN_NOT_BE_EMPTY_STRING' }.trim_space(),
		vmod.decode(@VMOD_FILE) or { vmod.Manifest{} }.unknown['lib_filenames'] or {
			[
				'CAN_NOT_BE_EMPTY_STRING',
			]
		}[0].split(',')[4] or { 'CAN_NOT_BE_EMPTY_STRING' }.trim_space(),
		//'a.out',
		'a-1.dll',
		'a.so.1',
	]
}) or { panic('Could not create loader instance') }
pub const p_loader = &loader_instance

fn main() {
	string_array := get_string_array()
	array_struct := get_array_struct()
	flags := get_enum()
	union_t := get_union()
	println(unsafe { string_array[3].vstring() })
	println(unsafe { array_struct.arr[3].array_ptr.vstring() })
	// enu[1] is not set in C, so V sets it to output: unknown enum value
	println(unsafe { sm.Flag_bits(array_struct.enu[1]) })
	println(unsafe { sm.Flag_bits(flags) })
	println('union_t size: ${sizeof(union_t)} type: ${typeof(union_t).name}')
	union_t_value := unsafe { union_t.uint32[0] }
	println('union_t value: ${union_t_value}')

	sm.get_stub(p_loader, [2]sm.Flag_bits{init: sm.Flag_bits.bbb})

	get_stub_main([2]Flag_bits_main{init: Flag_bits_main.bbbb})
}
