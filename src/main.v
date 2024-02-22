module main

import dl.loader

#include <vulkan/vulkan.h>

pub fn vk_make_api_version(variant u32, major u32, minor u32, patch u32) u32 {
	return variant << 29 | major << 22 | minor << 12 | patch
}

pub const vk_header_version = 272

pub const vk_header_version_complete = vk_make_api_version(0, 1, 3, vk_header_version)

pub fn version_variant(version u32) u32 {
	return version >> 29
}

// pub type C.VkInstance = voidptr
// pub type VkInstance = voidptr
@[typedef]
pub struct C.VkInstance {}

pub enum VkResult {
	vk_success                                            = int(0)
	vk_not_ready                                          = int(1)
	vk_timeout                                            = int(2)
	vk_event_set                                          = int(3)
	vk_event_reset                                        = int(4)
	vk_incomplete                                         = int(5)
	vk_error_out_of_host_memory                           = int(-1)
	vk_error_out_of_device_memory                         = int(-2)
	vk_error_initialization_failed                        = int(-3)
	vk_error_device_lost                                  = int(-4)
	vk_error_memory_map_failed                            = int(-5)
	vk_error_layer_not_present                            = int(-6)
	vk_error_extension_not_present                        = int(-7)
	vk_error_feature_not_present                          = int(-8)
	vk_error_incompatible_driver                          = int(-9)
	vk_error_too_many_objects                             = int(-10)
	vk_error_format_not_supported                         = int(-11)
	vk_error_fragmented_pool                              = int(-12)
	vk_error_unknown                                      = int(-13)
	vk_error_out_of_pool_memory                           = int(-1000069000)
	vk_error_invalid_external_handle                      = int(-1000072003)
	vk_error_fragmentation                                = int(-1000161000)
	vk_error_invalid_opaque_capture_address               = int(-1000257000)
	vk_pipeline_compile_required                          = int(1000297000)
	vk_error_surface_lost_khr                             = int(-1000000000)
	vk_error_native_window_in_use_khr                     = int(-1000000001)
	vk_suboptimal_khr                                     = int(1000001003)
	vk_error_out_of_date_khr                              = int(-1000001004)
	vk_error_incompatible_display_khr                     = int(-1000003001)
	vk_error_validation_failed_ext                        = int(-1000011001)
	vk_error_invalid_shader_nv                            = int(-1000012000)
	vk_error_image_usage_not_supported_khr                = int(-1000023000)
	vk_error_video_picture_layout_not_supported_khr       = int(-1000023001)
	vk_error_video_profile_operation_not_supported_khr    = int(-1000023002)
	vk_error_video_profile_format_not_supported_khr       = int(-1000023003)
	vk_error_video_profile_codec_not_supported_khr        = int(-1000023004)
	vk_error_video_std_version_not_supported_khr          = int(-1000023005)
	vk_error_invalid_drm_format_modifier_plane_layout_ext = int(-1000158000)
	vk_error_not_permitted_khr                            = int(-1000174001)
	vk_error_full_screen_exclusive_mode_lost_ext          = int(-1000255000)
	vk_thread_idle_khr                                    = int(1000268000)
	vk_thread_done_khr                                    = int(1000268001)
	vk_operation_deferred_khr                             = int(1000268002)
	vk_operation_not_deferred_khr                         = int(1000268003)
	vk_error_compression_exhausted_ext                    = int(-1000338000)
	vk_error_incompatible_shader_binary_ext               = int(1000482000)
	vk_result_max_enum                                    = int(0x7FFFFFFF)
}

pub type VkInstanceCreateFlags = u32

pub enum VkStructureType {
	vk_structure_type_application_info     = int(0)
	vk_structure_type_instance_create_info = int(1)
}

pub struct VkApplicationInfo {
mut:
	s_type              VkStructureType
	p_next              voidptr
	p_application_name  &char
	application_version u32
	p_engine_name       &char
	engine_version      u32
	api_version         u32
}

pub type VkCreateInstance = fn (&VkInstanceCreateInfo, voidptr, &C.VkInstance) VkResult

pub fn create_instance(p_create_info &VkInstanceCreateInfo, p_allocator voidptr, p_instance &C.VkInstance) VkResult {
	mut dl_loader := loader.get_or_create_dynamic_lib_loader(key: 'vulkan', env_path: '', paths: [
		'libvulkan.so.1',
		'vulkan-1.dll',
	]) or {
		println("modules/vulkan/vulkan.v: Couldn't get or create dynamic lib loader: ${err}")
		return VkResult.vk_error_unknown
	}
	defer {
		dl_loader.unregister()
	}

	println('loader loaded')

	sym := dl_loader.get_sym('vkCreateInstance') or {
		println("Couldn't load sym for vkCreateInstance: ${err}")
		return VkResult.vk_error_unknown
	}

	println('vkCreateInstance sym found')

	f := VkCreateInstance(sym)

	return f(p_create_info, p_allocator, p_instance)
}

pub enum VkSystemAllocationScope {
	vk_system_allocation_scope_command  = int(0)
	vk_system_allocation_scope_object   = int(1)
	vk_system_allocation_scope_cache    = int(2)
	vk_system_allocation_scope_device   = int(3)
	vk_system_allocation_scope_instance = int(4)
	vk_system_allocation_scope_max_enum = int(0x7FFFFFFF)
}

pub enum VkInternalAllocationType {
	vk_internal_allocation_type_executable = int(0)
	vk_internal_allocation_type_max_enum   = int(0x7FFFFFFF)
}


pub struct VkInstanceCreateInfo {
mut:
	s_type                     VkStructureType
	p_next                     voidptr
	flags                      VkInstanceCreateFlags
	p_application_info         &VkApplicationInfo
	enabled_layer_count        u32
	pp_enabled_layer_names     &char
	enabled_extension_count    u32
	pp_enabled_extension_names &char
}

struct Data {
mut:
	some_val int = 123
}

fn main() {
	enabled_layer_names := ''.str
	enabled_extension_names := ''.str
	mut data := Data{}
	// This is filled in create_instance
	mut instance := unsafe { &C.VkInstance(malloc(int(sizeof(C.VkInstance)))) }

	mut create_info := VkInstanceCreateInfo{
		s_type: VkStructureType.vk_structure_type_instance_create_info
		flags: 0
		p_application_info: &VkApplicationInfo{
			p_application_name: c'Vulkan in Vlang'
			p_engine_name: c'This is not an Engine... yet'
			api_version: vk_header_version_complete
		}
		pp_enabled_layer_names: enabled_layer_names
		enabled_layer_count: 0
		enabled_extension_count: 0
		pp_enabled_extension_names: enabled_extension_names
	}

	mut vk_result := create_instance(&create_info, voidptr(0), instance)

	if vk_result != VkResult.vk_success {
		println("Couldn't create vulkan instance. VkResult: ${vk_result}")
	}
	// println("Created VkInstance ${instance}")
}
