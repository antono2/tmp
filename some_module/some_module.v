module some_module

import dl.loader

pub enum Flag_bits {
	aaa = 0
	bbb = 1
	ccc = 2
}

// @[keep_args_alive] //error
fn C.get_stub([2]Flag_bits)

pub type PFN_get_stub = fn ([2]Flag_bits)

@[inline]
pub fn get_stub(p_loader &loader.DynamicLibLoader, param [2]Flag_bits) {
	f := PFN_get_stub((*p_loader).get_sym('get_stub') or {
		println("Could not load symbol for 'get_stub': ${err}")
		return
	})
	f(param)
}
