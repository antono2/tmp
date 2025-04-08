module some_module

pub enum Flag_bits {
	aaa = 0
	bbb = 1
	ccc = 2
}

pub enum Flag_bits2 {
  dsntmatter2
}

@[keep_args_alive]
fn C.get_stub([2]Flag_bits)

pub type PFN_get_stub = fn ([2]Flag_bits)

@[inline]
pub fn get_stub(param [2]Flag_bits) {
	C.get_stub(param)
}
