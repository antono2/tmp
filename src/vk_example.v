module main

import time

#flag linux -L/usr/lib/x86_64-linux-gnu
#flag linux -lglfw
#flag linux -DGLFW_INCLUDE_VULKAN=1

#flag linux -I/usr/include
#flag linux -lvulkan

#include "GLFW/glfw3.h"
#include "vulkan/vulkan.h"

pub const glfw_true = 1
pub const glfw_press = 1 << 0
pub const glfw_key_enter = 257
pub const glfw_key_escape = 256

@[heap; typedef]
struct C.GLFWwindow {
}

pub type GLFWWindow = C.GLFWwindow

@[heap; typedef]
struct C.GLFWmonitor {
}

pub type GLFWMonitor = C.GLFWmonitor

fn init_app(window &GLFWWindow) App {
	new_app := App{
		main_window: unsafe { window }
		share_data: []
	}
	return new_app
}

@[heap]
struct App {
pub mut:
	main_window &GLFWWindow
	share_data  []string // some data to share between callback and main()
}

fn C.glfwInit() int
pub fn glfw_initialize() bool {
	return C.glfwInit() == glfw_true
}

fn C.glfwTerminate()
pub fn glfw_terminate() {
	C.glfwTerminate()
}

fn C.glfwCreateWindow(width int, height int, title &char, monitor &C.GLFWmonitor, window &C.GLFWwindow) &C.GLFWwindow
pub fn glfw_create_window_desc(width int, height int, title string, mut monitor GLFWMonitor, mut window GLFWWindow) &GLFWWindow {
	ret := C.glfwCreateWindow(width, height, title.str, monitor, window)
	return ret
}

fn C.glfwSetWindowUserPointer(window &C.GLFWwindow, pointer voidptr)
pub fn glfw_set_user_pointer(window &GLFWWindow, pointer voidptr) {
	C.glfwSetWindowUserPointer(window, pointer)
}

fn C.glfwGetWindowUserPointer(window &C.GLFWwindow) voidptr
pub fn glfw_get_user_pointer(window &GLFWWindow) voidptr {
	ptr := C.glfwGetWindowUserPointer(window)
	return ptr
}

pub type GLFWFnKey = fn (window &C.GLFWwindow, key_id int, scan_code int, action int, bit_filed int)

fn C.glfwSetKeyCallback(window &C.GLFWwindow, callback GLFWFnKey)
pub fn glfw_set_key_callback(window &GLFWWindow, callback GLFWFnKey) {
	C.glfwSetKeyCallback(window, callback)
}

fn C.glfwMakeContextCurrent(window &C.GLFWwindow)
pub fn glfw_make_context_current(window &GLFWWindow) {
	C.glfwMakeContextCurrent(window)
}

fn C.glfwVulkanSupported() int
pub fn glfw_is_vulkan_supported() bool {
	return C.glfwVulkanSupported() == glfw_true
}

fn C.glfwSetWindowShouldClose(window &C.GLFWwindow, value int)
pub fn glfw_set_should_close(window &GLFWWindow, flag int) {
	C.glfwSetWindowShouldClose(window, flag)
}

fn C.glfwWindowShouldClose(window &C.GLFWwindow) int
pub fn glfw_window_should_close(window &GLFWWindow) bool {
	return C.glfwWindowShouldClose(window) == glfw_true
}

fn C.glfwPollEvents()
pub fn glfw_poll_events() {
	C.glfwPollEvents()
}

fn is_device_suitable(device &C.PhysicalDevice) bool {
	device_properties := PhysicalDeviceProperties{}
	get_physical_device_properties(device, device_properties)
	return device_properties.device_type == PhysicalDeviceType.physical_device_type_discrete_gpu
}

fn main() {
	mut instance := unsafe { nil }
	defer {
		glfw_terminate()
		unsafe {
			free(instance)
		}
	}

	// initialize the GLFW ("init" is a reserved keyword in V)
	glfw_initialize()

	mut monitor := unsafe { nil }
	mut window := unsafe { nil }
	window = glfw_create_window_desc(960, 480, 'Vulkan', mut monitor, mut window)

	mut app := init_app(window)

	// set user pointer to &App
	glfw_set_user_pointer(window, &app)
	// set callback function for keyboard input
	glfw_set_key_callback(window, key_callback_function)
	glfw_make_context_current(window)

	if !glfw_is_vulkan_supported() {
		panic('Vulkan is not available')
	}

	create_info := InstanceCreateInfo{
		s_type: StructureType.structure_type_instance_create_info
		flags: 0
		p_application_info: &ApplicationInfo{
			p_application_name: c'Vulkan in Vlang'
			p_engine_name: c'This is not an Engine... yet'
			api_version: api_version_1_0 // header_version_complete
		}
		// TODO: VK_KHR_surface extension for glfw
		pp_enabled_layer_names: unsafe { nil }
		enabled_layer_count: 0
		pp_enabled_extension_names: unsafe { nil }
		enabled_extension_count: 0
	}
	result := create_instance(create_info, unsafe { nil }, &instance)

	if result != Result.success {
		println("Couldn't create vulkan instance. VkResult: ${result}")
	} else {
		println('Created VkInstance ${instance}')
	}

	mut physical_device_cnt := u32(0)
	enumerate_physical_devices(instance, &physical_device_cnt, unsafe { nil })
	if physical_device_cnt == 0 {
		panic("Couldn't find GPUs with vulkan support")
	}
	println('device count: ${physical_device_cnt}')
	mut devices_c := create_c_array[PhysicalDevice](physical_device_cnt)
	dump('devices_c sizeof pre: ${sizeof(devices_c)} bytes')
	if enumerate_physical_devices(instance, &physical_device_cnt, devices_c) != Result.success {
		panic("Couldn't enumerate physical devices")
	}
	devices := to_v_array[PhysicalDevice](devices_c, physical_device_cnt)
	for i in 0 .. physical_device_cnt {
		dump(devices[i])
		if is_device_suitable(devices[i]) {
			println('found device')
		}
	}

	println('Success!')
	exit(0)
	// TODO: continue implementation here
	// glfw.get_physical_device_presentation_support((*instance), )

	for !(glfw_window_should_close(window)) {
		/*
			<-- Here you can do the rendering stuff and so on.. -->
		 */
		// now print the data (which could come from callback) from the app struct and remove it afterwards
		for _, s in app.share_data {
			println(s)
		}
		app.share_data = []
		glfw_poll_events()
	}
}

// Called on a keyboard event
// GLFW_PRESS, GLFW_RELEASE or GLFW_REPEAT
// https://www.glfw.org/docs/latest/group__keys.html
fn key_callback_function(window &GLFWWindow, key int, scancode int, action int, mods int) {
	if action == glfw_press {
		// transfer the data to the app struct
		mut app := unsafe { &App(glfw_get_user_pointer(window)) }
		if key == glfw_key_enter {
			// if enter key pressed
			txt := 'Enter-key Pressed at ${time.now().str()}'
			app.share_data << txt
		}
		if key == glfw_key_escape {
			unsafe { glfw_set_should_close(window, 1) }
		}
	}
}

fn create_c_array_handles[T](len u32) []T {
	return unsafe { []T{len: int(len), init: T(malloc(int(sizeof(T))))} }
}

fn create_c_array[T](len u32) voidptr {
	return unsafe { &T(malloc(int(sizeof(T) * len))) }
}

// NOTE: array d is consumed/freed
fn to_v_array[T](d &T, len u32) []T {
	mut res := unsafe { []T{len: int(len)} }
	for i in 0 .. len {
		unsafe {
			res[i] = d[i]
		}
	}
	unsafe {
		free(d)
	}
	return res
}

pub struct InstanceCreateInfo {
pub mut:
	s_type                     StructureType
	p_next                     voidptr
	flags                      InstanceCreateFlags
	p_application_info         &ApplicationInfo
	enabled_layer_count        u32
	pp_enabled_layer_names     &char
	enabled_extension_count    u32
	pp_enabled_extension_names &char
}

pub fn make_api_version(variant u32, major u32, minor u32, patch u32) u32 {
	return variant << 29 | major << 22 | minor << 12 | patch
}

pub const api_version_1_0 = make_api_version(0, 1, 0, 0) // Patch version should always be set to 0
pub const header_version = 272

pub const header_version_complete = make_api_version(0, 1, 3, header_version)

pub fn version_variant(version u32) u32 {
	return version >> 29
}

pub fn api_version_major(version u32) u32 {
	return version >> 22 & u32(0x7F)
}

pub fn api_version_minor(version u32) u32 {
	return version >> 12 & u32(0x3FF)
}

pub fn api_version_patch(version u32) u32 {
	return version & u32(0xFFF)
}

pub enum InstanceCreateFlagBits {
	instance_create_enumerate_portability_bit_khr = int(0x00000001)
	instance_create_flag_bits_max_enum            = int(0x7FFFFFFF)
}

pub type InstanceCreateFlags = u32

pub struct ApplicationInfo {
pub mut:
	s_type              StructureType
	p_next              voidptr
	p_application_name  &char
	application_version u32
	p_engine_name       &char
	engine_version      u32
	api_version         u32
}

pub enum StructureType {
	structure_type_application_info                                                    = int(0)
	structure_type_instance_create_info                                                = int(1)
	structure_type_device_queue_create_info                                            = int(2)
	structure_type_device_create_info                                                  = int(3)
	structure_type_submit_info                                                         = int(4)
	structure_type_memory_allocate_info                                                = int(5)
	structure_type_mapped_memory_range                                                 = int(6)
	structure_type_bind_sparse_info                                                    = int(7)
	structure_type_fence_create_info                                                   = int(8)
	structure_type_semaphore_create_info                                               = int(9)
	structure_type_event_create_info                                                   = int(10)
	structure_type_query_pool_create_info                                              = int(11)
	structure_type_buffer_create_info                                                  = int(12)
	structure_type_buffer_view_create_info                                             = int(13)
	structure_type_image_create_info                                                   = int(14)
	structure_type_image_view_create_info                                              = int(15)
	structure_type_shader_module_create_info                                           = int(16)
	structure_type_pipeline_cache_create_info                                          = int(17)
	structure_type_pipeline_shader_stage_create_info                                   = int(18)
	structure_type_pipeline_vertex_input_state_create_info                             = int(19)
	structure_type_pipeline_input_assembly_state_create_info                           = int(20)
	structure_type_pipeline_tessellation_state_create_info                             = int(21)
	structure_type_pipeline_viewport_state_create_info                                 = int(22)
	structure_type_pipeline_rasterization_state_create_info                            = int(23)
	structure_type_pipeline_multisample_state_create_info                              = int(24)
	structure_type_pipeline_depth_stencil_state_create_info                            = int(25)
	structure_type_pipeline_color_blend_state_create_info                              = int(26)
	structure_type_pipeline_dynamic_state_create_info                                  = int(27)
	structure_type_graphics_pipeline_create_info                                       = int(28)
	structure_type_compute_pipeline_create_info                                        = int(29)
	structure_type_pipeline_layout_create_info                                         = int(30)
	structure_type_sampler_create_info                                                 = int(31)
	structure_type_descriptor_set_layout_create_info                                   = int(32)
	structure_type_descriptor_pool_create_info                                         = int(33)
	structure_type_descriptor_set_allocate_info                                        = int(34)
	structure_type_write_descriptor_set                                                = int(35)
	structure_type_copy_descriptor_set                                                 = int(36)
	structure_type_framebuffer_create_info                                             = int(37)
	structure_type_render_pass_create_info                                             = int(38)
	structure_type_command_pool_create_info                                            = int(39)
	structure_type_command_buffer_allocate_info                                        = int(40)
	structure_type_command_buffer_inheritance_info                                     = int(41)
	structure_type_command_buffer_begin_info                                           = int(42)
	structure_type_render_pass_begin_info                                              = int(43)
	structure_type_buffer_memory_barrier                                               = int(44)
	structure_type_image_memory_barrier                                                = int(45)
	structure_type_memory_barrier                                                      = int(46)
	structure_type_loader_instance_create_info                                         = int(47)
	structure_type_loader_device_create_info                                           = int(48)
	structure_type_physical_device_subgroup_properties                                 = int(1000094000)
	structure_type_bind_buffer_memory_info                                             = int(1000157000)
	structure_type_bind_image_memory_info                                              = int(1000157001)
	structure_type_physical_device_16bit_storage_features                              = int(1000083000)
	structure_type_memory_dedicated_requirements                                       = int(1000127000)
	structure_type_memory_dedicated_allocate_info                                      = int(1000127001)
	structure_type_memory_allocate_flags_info                                          = int(1000060000)
	structure_type_device_group_render_pass_begin_info                                 = int(1000060003)
	structure_type_device_group_command_buffer_begin_info                              = int(1000060004)
	structure_type_device_group_submit_info                                            = int(1000060005)
	structure_type_device_group_bind_sparse_info                                       = int(1000060006)
	structure_type_bind_buffer_memory_device_group_info                                = int(1000060013)
	structure_type_bind_image_memory_device_group_info                                 = int(1000060014)
	structure_type_physical_device_group_properties                                    = int(1000070000)
	structure_type_device_group_device_create_info                                     = int(1000070001)
	structure_type_buffer_memory_requirements_info_2                                   = int(1000146000)
	structure_type_image_memory_requirements_info_2                                    = int(1000146001)
	structure_type_image_sparse_memory_requirements_info_2                             = int(1000146002)
	structure_type_memory_requirements_2                                               = int(1000146003)
	structure_type_sparse_image_memory_requirements_2                                  = int(1000146004)
	structure_type_physical_device_features_2                                          = int(1000059000)
	structure_type_physical_device_properties_2                                        = int(1000059001)
	structure_type_format_properties_2                                                 = int(1000059002)
	structure_type_image_format_properties_2                                           = int(1000059003)
	structure_type_physical_device_image_format_info_2                                 = int(1000059004)
	structure_type_queue_family_properties_2                                           = int(1000059005)
	structure_type_physical_device_memory_properties_2                                 = int(1000059006)
	structure_type_sparse_image_format_properties_2                                    = int(1000059007)
	structure_type_physical_device_sparse_image_format_info_2                          = int(1000059008)
	structure_type_physical_device_point_clipping_properties                           = int(1000117000)
	structure_type_render_pass_input_attachment_aspect_create_info                     = int(1000117001)
	structure_type_image_view_usage_create_info                                        = int(1000117002)
	structure_type_pipeline_tessellation_domain_origin_state_create_info               = int(1000117003)
	structure_type_render_pass_multiview_create_info                                   = int(1000053000)
	structure_type_physical_device_multiview_features                                  = int(1000053001)
	structure_type_physical_device_multiview_properties                                = int(1000053002)
	structure_type_physical_device_variable_pointers_features                          = int(1000120000)
	structure_type_protected_submit_info                                               = int(1000145000)
	structure_type_physical_device_protected_memory_features                           = int(1000145001)
	structure_type_physical_device_protected_memory_properties                         = int(1000145002)
	structure_type_device_queue_info_2                                                 = int(1000145003)
	structure_type_sampler_ycbcr_conversion_create_info                                = int(1000156000)
	structure_type_sampler_ycbcr_conversion_info                                       = int(1000156001)
	structure_type_bind_image_plane_memory_info                                        = int(1000156002)
	structure_type_image_plane_memory_requirements_info                                = int(1000156003)
	structure_type_physical_device_sampler_ycbcr_conversion_features                   = int(1000156004)
	structure_type_sampler_ycbcr_conversion_image_format_properties                    = int(1000156005)
	structure_type_descriptor_update_template_create_info                              = int(1000085000)
	structure_type_physical_device_external_image_format_info                          = int(1000071000)
	structure_type_external_image_format_properties                                    = int(1000071001)
	structure_type_physical_device_external_buffer_info                                = int(1000071002)
	structure_type_external_buffer_properties                                          = int(1000071003)
	structure_type_physical_device_id_properties                                       = int(1000071004)
	structure_type_external_memory_buffer_create_info                                  = int(1000072000)
	structure_type_external_memory_image_create_info                                   = int(1000072001)
	structure_type_export_memory_allocate_info                                         = int(1000072002)
	structure_type_physical_device_external_fence_info                                 = int(1000112000)
	structure_type_external_fence_properties                                           = int(1000112001)
	structure_type_export_fence_create_info                                            = int(1000113000)
	structure_type_export_semaphore_create_info                                        = int(1000077000)
	structure_type_physical_device_external_semaphore_info                             = int(1000076000)
	structure_type_external_semaphore_properties                                       = int(1000076001)
	structure_type_physical_device_maintenance_3_properties                            = int(1000168000)
	structure_type_descriptor_set_layout_support                                       = int(1000168001)
	structure_type_physical_device_shader_draw_parameters_features                     = int(1000063000)
	structure_type_physical_device_vulkan_1_1_features                                 = int(49)
	structure_type_physical_device_vulkan_1_1_properties                               = int(50)
	structure_type_physical_device_vulkan_1_2_features                                 = int(51)
	structure_type_physical_device_vulkan_1_2_properties                               = int(52)
	structure_type_image_format_list_create_info                                       = int(1000147000)
	structure_type_attachment_description_2                                            = int(1000109000)
	structure_type_attachment_reference_2                                              = int(1000109001)
	structure_type_subpass_description_2                                               = int(1000109002)
	structure_type_subpass_dependency_2                                                = int(1000109003)
	structure_type_render_pass_create_info_2                                           = int(1000109004)
	structure_type_subpass_begin_info                                                  = int(1000109005)
	structure_type_subpass_end_info                                                    = int(1000109006)
	structure_type_physical_device_8bit_storage_features                               = int(1000177000)
	structure_type_physical_device_driver_properties                                   = int(1000196000)
	structure_type_physical_device_shader_atomic_int64_features                        = int(1000180000)
	structure_type_physical_device_shader_float16_int8_features                        = int(1000082000)
	structure_type_physical_device_float_controls_properties                           = int(1000197000)
	structure_type_descriptor_set_layout_binding_flags_create_info                     = int(1000161000)
	structure_type_physical_device_descriptor_indexing_features                        = int(1000161001)
	structure_type_physical_device_descriptor_indexing_properties                      = int(1000161002)
	structure_type_descriptor_set_variable_descriptor_count_allocate_info              = int(1000161003)
	structure_type_descriptor_set_variable_descriptor_count_layout_support             = int(1000161004)
	structure_type_physical_device_depth_stencil_resolve_properties                    = int(1000199000)
	structure_type_subpass_description_depth_stencil_resolve                           = int(1000199001)
	structure_type_physical_device_scalar_block_layout_features                        = int(1000221000)
	structure_type_image_stencil_usage_create_info                                     = int(1000246000)
	structure_type_physical_device_sampler_filter_minmax_properties                    = int(1000130000)
	structure_type_sampler_reduction_mode_create_info                                  = int(1000130001)
	structure_type_physical_device_vulkan_memory_model_features                        = int(1000211000)
	structure_type_physical_device_imageless_framebuffer_features                      = int(1000108000)
	structure_type_framebuffer_attachments_create_info                                 = int(1000108001)
	structure_type_framebuffer_attachment_image_info                                   = int(1000108002)
	structure_type_render_pass_attachment_begin_info                                   = int(1000108003)
	structure_type_physical_device_uniform_buffer_standard_layout_features             = int(1000253000)
	structure_type_physical_device_shader_subgroup_extended_types_features             = int(1000175000)
	structure_type_physical_device_separate_depth_stencil_layouts_features             = int(1000241000)
	structure_type_attachment_reference_stencil_layout                                 = int(1000241001)
	structure_type_attachment_description_stencil_layout                               = int(1000241002)
	structure_type_physical_device_host_query_reset_features                           = int(1000261000)
	structure_type_physical_device_timeline_semaphore_features                         = int(1000207000)
	structure_type_physical_device_timeline_semaphore_properties                       = int(1000207001)
	structure_type_semaphore_type_create_info                                          = int(1000207002)
	structure_type_timeline_semaphore_submit_info                                      = int(1000207003)
	structure_type_semaphore_wait_info                                                 = int(1000207004)
	structure_type_semaphore_signal_info                                               = int(1000207005)
	structure_type_physical_device_buffer_device_address_features                      = int(1000257000)
	structure_type_buffer_device_address_info                                          = int(1000244001)
	structure_type_buffer_opaque_capture_address_create_info                           = int(1000257002)
	structure_type_memory_opaque_capture_address_allocate_info                         = int(1000257003)
	structure_type_device_memory_opaque_capture_address_info                           = int(1000257004)
	structure_type_physical_device_vulkan_1_3_features                                 = int(53)
	structure_type_physical_device_vulkan_1_3_properties                               = int(54)
	structure_type_pipeline_creation_feedback_create_info                              = int(1000192000)
	structure_type_physical_device_shader_terminate_invocation_features                = int(1000215000)
	structure_type_physical_device_tool_properties                                     = int(1000245000)
	structure_type_physical_device_shader_demote_to_helper_invocation_features         = int(1000276000)
	structure_type_physical_device_private_data_features                               = int(1000295000)
	structure_type_device_private_data_create_info                                     = int(1000295001)
	structure_type_private_data_slot_create_info                                       = int(1000295002)
	structure_type_physical_device_pipeline_creation_cache_control_features            = int(1000297000)
	structure_type_memory_barrier_2                                                    = int(1000314000)
	structure_type_buffer_memory_barrier_2                                             = int(1000314001)
	structure_type_image_memory_barrier_2                                              = int(1000314002)
	structure_type_dependency_info                                                     = int(1000314003)
	structure_type_submit_info_2                                                       = int(1000314004)
	structure_type_semaphore_submit_info                                               = int(1000314005)
	structure_type_command_buffer_submit_info                                          = int(1000314006)
	structure_type_physical_device_synchronization_2_features                          = int(1000314007)
	structure_type_physical_device_zero_initialize_workgroup_memory_features           = int(1000325000)
	structure_type_physical_device_image_robustness_features                           = int(1000335000)
	structure_type_copy_buffer_info_2                                                  = int(1000337000)
	structure_type_copy_image_info_2                                                   = int(1000337001)
	structure_type_copy_buffer_to_image_info_2                                         = int(1000337002)
	structure_type_copy_image_to_buffer_info_2                                         = int(1000337003)
	structure_type_blit_image_info_2                                                   = int(1000337004)
	structure_type_resolve_image_info_2                                                = int(1000337005)
	structure_type_buffer_copy_2                                                       = int(1000337006)
	structure_type_image_copy_2                                                        = int(1000337007)
	structure_type_image_blit_2                                                        = int(1000337008)
	structure_type_buffer_image_copy_2                                                 = int(1000337009)
	structure_type_image_resolve_2                                                     = int(1000337010)
	structure_type_physical_device_subgroup_size_control_properties                    = int(1000225000)
	structure_type_pipeline_shader_stage_required_subgroup_size_create_info            = int(1000225001)
	structure_type_physical_device_subgroup_size_control_features                      = int(1000225002)
	structure_type_physical_device_inline_uniform_block_features                       = int(1000138000)
	structure_type_physical_device_inline_uniform_block_properties                     = int(1000138001)
	structure_type_write_descriptor_set_inline_uniform_block                           = int(1000138002)
	structure_type_descriptor_pool_inline_uniform_block_create_info                    = int(1000138003)
	structure_type_physical_device_texture_compression_astc_hdr_features               = int(1000066000)
	structure_type_rendering_info                                                      = int(1000044000)
	structure_type_rendering_attachment_info                                           = int(1000044001)
	structure_type_pipeline_rendering_create_info                                      = int(1000044002)
	structure_type_physical_device_dynamic_rendering_features                          = int(1000044003)
	structure_type_command_buffer_inheritance_rendering_info                           = int(1000044004)
	structure_type_physical_device_shader_integer_dot_product_features                 = int(1000280000)
	structure_type_physical_device_shader_integer_dot_product_properties               = int(1000280001)
	structure_type_physical_device_texel_buffer_alignment_properties                   = int(1000281001)
	structure_type_format_properties_3                                                 = int(1000360000)
	structure_type_physical_device_maintenance_4_features                              = int(1000413000)
	structure_type_physical_device_maintenance_4_properties                            = int(1000413001)
	structure_type_device_buffer_memory_requirements                                   = int(1000413002)
	structure_type_device_image_memory_requirements                                    = int(1000413003)
	structure_type_swapchain_create_info_khr                                           = int(1000001000)
	structure_type_present_info_khr                                                    = int(1000001001)
	structure_type_device_group_present_capabilities_khr                               = int(1000060007)
	structure_type_image_swapchain_create_info_khr                                     = int(1000060008)
	structure_type_bind_image_memory_swapchain_info_khr                                = int(1000060009)
	structure_type_acquire_next_image_info_khr                                         = int(1000060010)
	structure_type_device_group_present_info_khr                                       = int(1000060011)
	structure_type_device_group_swapchain_create_info_khr                              = int(1000060012)
	structure_type_display_mode_create_info_khr                                        = int(1000002000)
	structure_type_display_surface_create_info_khr                                     = int(1000002001)
	structure_type_display_present_info_khr                                            = int(1000003000)
	structure_type_xlib_surface_create_info_khr                                        = int(1000004000)
	structure_type_xcb_surface_create_info_khr                                         = int(1000005000)
	structure_type_wayland_surface_create_info_khr                                     = int(1000006000)
	structure_type_android_surface_create_info_khr                                     = int(1000008000)
	structure_type_win32_surface_create_info_khr                                       = int(1000009000)
	structure_type_debug_report_callback_create_info_ext                               = int(1000011000)
	structure_type_pipeline_rasterization_state_rasterization_order_amd                = int(1000018000)
	structure_type_debug_marker_object_name_info_ext                                   = int(1000022000)
	structure_type_debug_marker_object_tag_info_ext                                    = int(1000022001)
	structure_type_debug_marker_marker_info_ext                                        = int(1000022002)
	structure_type_video_profile_info_khr                                              = int(1000023000)
	structure_type_video_capabilities_khr                                              = int(1000023001)
	structure_type_video_picture_resource_info_khr                                     = int(1000023002)
	structure_type_video_session_memory_requirements_khr                               = int(1000023003)
	structure_type_bind_video_session_memory_info_khr                                  = int(1000023004)
	structure_type_video_session_create_info_khr                                       = int(1000023005)
	structure_type_video_session_parameters_create_info_khr                            = int(1000023006)
	structure_type_video_session_parameters_update_info_khr                            = int(1000023007)
	structure_type_video_begin_coding_info_khr                                         = int(1000023008)
	structure_type_video_end_coding_info_khr                                           = int(1000023009)
	structure_type_video_coding_control_info_khr                                       = int(1000023010)
	structure_type_video_reference_slot_info_khr                                       = int(1000023011)
	structure_type_queue_family_video_properties_khr                                   = int(1000023012)
	structure_type_video_profile_list_info_khr                                         = int(1000023013)
	structure_type_physical_device_video_format_info_khr                               = int(1000023014)
	structure_type_video_format_properties_khr                                         = int(1000023015)
	structure_type_queue_family_query_result_status_properties_khr                     = int(1000023016)
	structure_type_video_decode_info_khr                                               = int(1000024000)
	structure_type_video_decode_capabilities_khr                                       = int(1000024001)
	structure_type_video_decode_usage_info_khr                                         = int(1000024002)
	structure_type_dedicated_allocation_image_create_info_nv                           = int(1000026000)
	structure_type_dedicated_allocation_buffer_create_info_nv                          = int(1000026001)
	structure_type_dedicated_allocation_memory_allocate_info_nv                        = int(1000026002)
	structure_type_physical_device_transform_feedback_features_ext                     = int(1000028000)
	structure_type_physical_device_transform_feedback_properties_ext                   = int(1000028001)
	structure_type_pipeline_rasterization_state_stream_create_info_ext                 = int(1000028002)
	structure_type_cu_module_create_info_nvx                                           = int(1000029000)
	structure_type_cu_function_create_info_nvx                                         = int(1000029001)
	structure_type_cu_launch_info_nvx                                                  = int(1000029002)
	structure_type_image_view_handle_info_nvx                                          = int(1000030000)
	structure_type_image_view_address_properties_nvx                                   = int(1000030001)
	structure_type_video_decode_h264_capabilities_khr                                  = int(1000040000)
	structure_type_video_decode_h264_picture_info_khr                                  = int(1000040001)
	structure_type_video_decode_h264_profile_info_khr                                  = int(1000040003)
	structure_type_video_decode_h264_session_parameters_create_info_khr                = int(1000040004)
	structure_type_video_decode_h264_session_parameters_add_info_khr                   = int(1000040005)
	structure_type_video_decode_h264_dpb_slot_info_khr                                 = int(1000040006)
	structure_type_texture_lod_gather_format_properties_amd                            = int(1000041000)
	structure_type_rendering_fragment_shading_rate_attachment_info_khr                 = int(1000044006)
	structure_type_rendering_fragment_density_map_attachment_info_ext                  = int(1000044007)
	structure_type_attachment_sample_count_info_amd                                    = int(1000044008)
	structure_type_multiview_per_view_attributes_info_nvx                              = int(1000044009)
	structure_type_stream_descriptor_surface_create_info_ggp                           = int(1000049000)
	structure_type_physical_device_corner_sampled_image_features_nv                    = int(1000050000)
	structure_type_external_memory_image_create_info_nv                                = int(1000056000)
	structure_type_export_memory_allocate_info_nv                                      = int(1000056001)
	structure_type_import_memory_win32_handle_info_nv                                  = int(1000057000)
	structure_type_export_memory_win32_handle_info_nv                                  = int(1000057001)
	structure_type_win32_keyed_mutex_acquire_release_info_nv                           = int(1000058000)
	structure_type_validation_flags_ext                                                = int(1000061000)
	structure_type_vi_surface_create_info_nn                                           = int(1000062000)
	structure_type_image_view_astc_decode_mode_ext                                     = int(1000067000)
	structure_type_physical_device_astc_decode_features_ext                            = int(1000067001)
	structure_type_pipeline_robustness_create_info_ext                                 = int(1000068000)
	structure_type_physical_device_pipeline_robustness_features_ext                    = int(1000068001)
	structure_type_physical_device_pipeline_robustness_properties_ext                  = int(1000068002)
	structure_type_import_memory_win32_handle_info_khr                                 = int(1000073000)
	structure_type_export_memory_win32_handle_info_khr                                 = int(1000073001)
	structure_type_memory_win32_handle_properties_khr                                  = int(1000073002)
	structure_type_memory_get_win32_handle_info_khr                                    = int(1000073003)
	structure_type_import_memory_fd_info_khr                                           = int(1000074000)
	structure_type_memory_fd_properties_khr                                            = int(1000074001)
	structure_type_memory_get_fd_info_khr                                              = int(1000074002)
	structure_type_win32_keyed_mutex_acquire_release_info_khr                          = int(1000075000)
	structure_type_import_semaphore_win32_handle_info_khr                              = int(1000078000)
	structure_type_export_semaphore_win32_handle_info_khr                              = int(1000078001)
	structure_type_d3d12_fence_submit_info_khr                                         = int(1000078002)
	structure_type_semaphore_get_win32_handle_info_khr                                 = int(1000078003)
	structure_type_import_semaphore_fd_info_khr                                        = int(1000079000)
	structure_type_semaphore_get_fd_info_khr                                           = int(1000079001)
	structure_type_physical_device_push_descriptor_properties_khr                      = int(1000080000)
	structure_type_command_buffer_inheritance_conditional_rendering_info_ext           = int(1000081000)
	structure_type_physical_device_conditional_rendering_features_ext                  = int(1000081001)
	structure_type_conditional_rendering_begin_info_ext                                = int(1000081002)
	structure_type_present_regions_khr                                                 = int(1000084000)
	structure_type_pipeline_viewport_w_scaling_state_create_info_nv                    = int(1000087000)
	structure_type_surface_capabilities_2_ext                                          = int(1000090000)
	structure_type_display_power_info_ext                                              = int(1000091000)
	structure_type_device_event_info_ext                                               = int(1000091001)
	structure_type_display_event_info_ext                                              = int(1000091002)
	structure_type_swapchain_counter_create_info_ext                                   = int(1000091003)
	structure_type_present_times_info_google                                           = int(1000092000)
	structure_type_physical_device_multiview_per_view_attributes_properties_nvx        = int(1000097000)
	structure_type_pipeline_viewport_swizzle_state_create_info_nv                      = int(1000098000)
	structure_type_physical_device_discard_rectangle_properties_ext                    = int(1000099000)
	structure_type_pipeline_discard_rectangle_state_create_info_ext                    = int(1000099001)
	structure_type_physical_device_conservative_rasterization_properties_ext           = int(1000101000)
	structure_type_pipeline_rasterization_conservative_state_create_info_ext           = int(1000101001)
	structure_type_physical_device_depth_clip_enable_features_ext                      = int(1000102000)
	structure_type_pipeline_rasterization_depth_clip_state_create_info_ext             = int(1000102001)
	structure_type_hdr_metadata_ext                                                    = int(1000105000)
	structure_type_physical_device_relaxed_line_rasterization_features_img             = int(1000110000)
	structure_type_shared_present_surface_capabilities_khr                             = int(1000111000)
	structure_type_import_fence_win32_handle_info_khr                                  = int(1000114000)
	structure_type_export_fence_win32_handle_info_khr                                  = int(1000114001)
	structure_type_fence_get_win32_handle_info_khr                                     = int(1000114002)
	structure_type_import_fence_fd_info_khr                                            = int(1000115000)
	structure_type_fence_get_fd_info_khr                                               = int(1000115001)
	structure_type_physical_device_performance_query_features_khr                      = int(1000116000)
	structure_type_physical_device_performance_query_properties_khr                    = int(1000116001)
	structure_type_query_pool_performance_create_info_khr                              = int(1000116002)
	structure_type_performance_query_submit_info_khr                                   = int(1000116003)
	structure_type_acquire_profiling_lock_info_khr                                     = int(1000116004)
	structure_type_performance_counter_khr                                             = int(1000116005)
	structure_type_performance_counter_description_khr                                 = int(1000116006)
	structure_type_physical_device_surface_info_2_khr                                  = int(1000119000)
	structure_type_surface_capabilities_2_khr                                          = int(1000119001)
	structure_type_surface_format_2_khr                                                = int(1000119002)
	structure_type_display_properties_2_khr                                            = int(1000121000)
	structure_type_display_plane_properties_2_khr                                      = int(1000121001)
	structure_type_display_mode_properties_2_khr                                       = int(1000121002)
	structure_type_display_plane_info_2_khr                                            = int(1000121003)
	structure_type_display_plane_capabilities_2_khr                                    = int(1000121004)
	structure_type_ios_surface_create_info_mvk                                         = int(1000122000)
	structure_type_macos_surface_create_info_mvk                                       = int(1000123000)
	structure_type_debug_utils_object_name_info_ext                                    = int(1000128000)
	structure_type_debug_utils_object_tag_info_ext                                     = int(1000128001)
	structure_type_debug_utils_label_ext                                               = int(1000128002)
	structure_type_debug_utils_messenger_callback_data_ext                             = int(1000128003)
	structure_type_debug_utils_messenger_create_info_ext                               = int(1000128004)
	structure_type_android_hardware_buffer_usage_android                               = int(1000129000)
	structure_type_android_hardware_buffer_properties_android                          = int(1000129001)
	structure_type_android_hardware_buffer_format_properties_android                   = int(1000129002)
	structure_type_import_android_hardware_buffer_info_android                         = int(1000129003)
	structure_type_memory_get_android_hardware_buffer_info_android                     = int(1000129004)
	structure_type_external_format_android                                             = int(1000129005)
	structure_type_android_hardware_buffer_format_properties_2_android                 = int(1000129006)
	structure_type_sample_locations_info_ext                                           = int(1000143000)
	structure_type_render_pass_sample_locations_begin_info_ext                         = int(1000143001)
	structure_type_pipeline_sample_locations_state_create_info_ext                     = int(1000143002)
	structure_type_physical_device_sample_locations_properties_ext                     = int(1000143003)
	structure_type_multisample_properties_ext                                          = int(1000143004)
	structure_type_physical_device_blend_operation_advanced_features_ext               = int(1000148000)
	structure_type_physical_device_blend_operation_advanced_properties_ext             = int(1000148001)
	structure_type_pipeline_color_blend_advanced_state_create_info_ext                 = int(1000148002)
	structure_type_pipeline_coverage_to_color_state_create_info_nv                     = int(1000149000)
	structure_type_write_descriptor_set_acceleration_structure_khr                     = int(1000150007)
	structure_type_acceleration_structure_build_geometry_info_khr                      = int(1000150000)
	structure_type_acceleration_structure_device_address_info_khr                      = int(1000150002)
	structure_type_acceleration_structure_geometry_aabbs_data_khr                      = int(1000150003)
	structure_type_acceleration_structure_geometry_instances_data_khr                  = int(1000150004)
	structure_type_acceleration_structure_geometry_triangles_data_khr                  = int(1000150005)
	structure_type_acceleration_structure_geometry_khr                                 = int(1000150006)
	structure_type_acceleration_structure_version_info_khr                             = int(1000150009)
	structure_type_copy_acceleration_structure_info_khr                                = int(1000150010)
	structure_type_copy_acceleration_structure_to_memory_info_khr                      = int(1000150011)
	structure_type_copy_memory_to_acceleration_structure_info_khr                      = int(1000150012)
	structure_type_physical_device_acceleration_structure_features_khr                 = int(1000150013)
	structure_type_physical_device_acceleration_structure_properties_khr               = int(1000150014)
	structure_type_acceleration_structure_create_info_khr                              = int(1000150017)
	structure_type_acceleration_structure_build_sizes_info_khr                         = int(1000150020)
	structure_type_physical_device_ray_tracing_pipeline_features_khr                   = int(1000347000)
	structure_type_physical_device_ray_tracing_pipeline_properties_khr                 = int(1000347001)
	structure_type_ray_tracing_pipeline_create_info_khr                                = int(1000150015)
	structure_type_ray_tracing_shader_group_create_info_khr                            = int(1000150016)
	structure_type_ray_tracing_pipeline_interface_create_info_khr                      = int(1000150018)
	structure_type_physical_device_ray_query_features_khr                              = int(1000348013)
	structure_type_pipeline_coverage_modulation_state_create_info_nv                   = int(1000152000)
	structure_type_physical_device_shader_sm_builtins_features_nv                      = int(1000154000)
	structure_type_physical_device_shader_sm_builtins_properties_nv                    = int(1000154001)
	structure_type_drm_format_modifier_properties_list_ext                             = int(1000158000)
	structure_type_physical_device_image_drm_format_modifier_info_ext                  = int(1000158002)
	structure_type_image_drm_format_modifier_list_create_info_ext                      = int(1000158003)
	structure_type_image_drm_format_modifier_explicit_create_info_ext                  = int(1000158004)
	structure_type_image_drm_format_modifier_properties_ext                            = int(1000158005)
	structure_type_drm_format_modifier_properties_list_2_ext                           = int(1000158006)
	structure_type_validation_cache_create_info_ext                                    = int(1000160000)
	structure_type_shader_module_validation_cache_create_info_ext                      = int(1000160001)
	structure_type_pipeline_viewport_shading_rate_image_state_create_info_nv           = int(1000164000)
	structure_type_physical_device_shading_rate_image_features_nv                      = int(1000164001)
	structure_type_physical_device_shading_rate_image_properties_nv                    = int(1000164002)
	structure_type_pipeline_viewport_coarse_sample_order_state_create_info_nv          = int(1000164005)
	structure_type_ray_tracing_pipeline_create_info_nv                                 = int(1000165000)
	structure_type_acceleration_structure_create_info_nv                               = int(1000165001)
	structure_type_geometry_nv                                                         = int(1000165003)
	structure_type_geometry_triangles_nv                                               = int(1000165004)
	structure_type_geometry_aabb_nv                                                    = int(1000165005)
	structure_type_bind_acceleration_structure_memory_info_nv                          = int(1000165006)
	structure_type_write_descriptor_set_acceleration_structure_nv                      = int(1000165007)
	structure_type_acceleration_structure_memory_requirements_info_nv                  = int(1000165008)
	structure_type_physical_device_ray_tracing_properties_nv                           = int(1000165009)
	structure_type_ray_tracing_shader_group_create_info_nv                             = int(1000165011)
	structure_type_acceleration_structure_info_nv                                      = int(1000165012)
	structure_type_physical_device_representative_fragment_test_features_nv            = int(1000166000)
	structure_type_pipeline_representative_fragment_test_state_create_info_nv          = int(1000166001)
	structure_type_physical_device_image_view_image_format_info_ext                    = int(1000170000)
	structure_type_filter_cubic_image_view_image_format_properties_ext                 = int(1000170001)
	structure_type_import_memory_host_pointer_info_ext                                 = int(1000178000)
	structure_type_memory_host_pointer_properties_ext                                  = int(1000178001)
	structure_type_physical_device_external_memory_host_properties_ext                 = int(1000178002)
	structure_type_physical_device_shader_clock_features_khr                           = int(1000181000)
	structure_type_pipeline_compiler_control_create_info_amd                           = int(1000183000)
	structure_type_calibrated_timestamp_info_ext                                       = int(1000184000)
	structure_type_physical_device_shader_core_properties_amd                          = int(1000185000)
	structure_type_video_decode_h265_capabilities_khr                                  = int(1000187000)
	structure_type_video_decode_h265_session_parameters_create_info_khr                = int(1000187001)
	structure_type_video_decode_h265_session_parameters_add_info_khr                   = int(1000187002)
	structure_type_video_decode_h265_profile_info_khr                                  = int(1000187003)
	structure_type_video_decode_h265_picture_info_khr                                  = int(1000187004)
	structure_type_video_decode_h265_dpb_slot_info_khr                                 = int(1000187005)
	structure_type_device_queue_global_priority_create_info_khr                        = int(1000174000)
	structure_type_physical_device_global_priority_query_features_khr                  = int(1000388000)
	structure_type_queue_family_global_priority_properties_khr                         = int(1000388001)
	structure_type_device_memory_overallocation_create_info_amd                        = int(1000189000)
	structure_type_physical_device_vertex_attribute_divisor_properties_ext             = int(1000190000)
	structure_type_pipeline_vertex_input_divisor_state_create_info_ext                 = int(1000190001)
	structure_type_physical_device_vertex_attribute_divisor_features_ext               = int(1000190002)
	structure_type_present_frame_token_ggp                                             = int(1000191000)
	structure_type_physical_device_compute_shader_derivatives_features_nv              = int(1000201000)
	structure_type_physical_device_mesh_shader_features_nv                             = int(1000202000)
	structure_type_physical_device_mesh_shader_properties_nv                           = int(1000202001)
	structure_type_physical_device_shader_image_footprint_features_nv                  = int(1000204000)
	structure_type_pipeline_viewport_exclusive_scissor_state_create_info_nv            = int(1000205000)
	structure_type_physical_device_exclusive_scissor_features_nv                       = int(1000205002)
	structure_type_checkpoint_data_nv                                                  = int(1000206000)
	structure_type_queue_family_checkpoint_properties_nv                               = int(1000206001)
	structure_type_physical_device_shader_integer_functions_2_features_intel           = int(1000209000)
	structure_type_query_pool_performance_query_create_info_intel                      = int(1000210000)
	structure_type_initialize_performance_api_info_intel                               = int(1000210001)
	structure_type_performance_marker_info_intel                                       = int(1000210002)
	structure_type_performance_stream_marker_info_intel                                = int(1000210003)
	structure_type_performance_override_info_intel                                     = int(1000210004)
	structure_type_performance_configuration_acquire_info_intel                        = int(1000210005)
	structure_type_physical_device_pci_bus_info_properties_ext                         = int(1000212000)
	structure_type_display_native_hdr_surface_capabilities_amd                         = int(1000213000)
	structure_type_swapchain_display_native_hdr_create_info_amd                        = int(1000213001)
	structure_type_imagepipe_surface_create_info_fuchsia                               = int(1000214000)
	structure_type_metal_surface_create_info_ext                                       = int(1000217000)
	structure_type_physical_device_fragment_density_map_features_ext                   = int(1000218000)
	structure_type_physical_device_fragment_density_map_properties_ext                 = int(1000218001)
	structure_type_render_pass_fragment_density_map_create_info_ext                    = int(1000218002)
	structure_type_fragment_shading_rate_attachment_info_khr                           = int(1000226000)
	structure_type_pipeline_fragment_shading_rate_state_create_info_khr                = int(1000226001)
	structure_type_physical_device_fragment_shading_rate_properties_khr                = int(1000226002)
	structure_type_physical_device_fragment_shading_rate_features_khr                  = int(1000226003)
	structure_type_physical_device_fragment_shading_rate_khr                           = int(1000226004)
	structure_type_physical_device_shader_core_properties_2_amd                        = int(1000227000)
	structure_type_physical_device_coherent_memory_features_amd                        = int(1000229000)
	structure_type_physical_device_shader_image_atomic_int64_features_ext              = int(1000234000)
	structure_type_physical_device_memory_budget_properties_ext                        = int(1000237000)
	structure_type_physical_device_memory_priority_features_ext                        = int(1000238000)
	structure_type_memory_priority_allocate_info_ext                                   = int(1000238001)
	structure_type_surface_protected_capabilities_khr                                  = int(1000239000)
	structure_type_physical_device_dedicated_allocation_image_aliasing_features_nv     = int(1000240000)
	structure_type_physical_device_buffer_device_address_features_ext                  = int(1000244000)
	structure_type_buffer_device_address_create_info_ext                               = int(1000244002)
	structure_type_validation_features_ext                                             = int(1000247000)
	structure_type_physical_device_present_wait_features_khr                           = int(1000248000)
	structure_type_physical_device_cooperative_matrix_features_nv                      = int(1000249000)
	structure_type_cooperative_matrix_properties_nv                                    = int(1000249001)
	structure_type_physical_device_cooperative_matrix_properties_nv                    = int(1000249002)
	structure_type_physical_device_coverage_reduction_mode_features_nv                 = int(1000250000)
	structure_type_pipeline_coverage_reduction_state_create_info_nv                    = int(1000250001)
	structure_type_framebuffer_mixed_samples_combination_nv                            = int(1000250002)
	structure_type_physical_device_fragment_shader_interlock_features_ext              = int(1000251000)
	structure_type_physical_device_ycbcr_image_arrays_features_ext                     = int(1000252000)
	structure_type_physical_device_provoking_vertex_features_ext                       = int(1000254000)
	structure_type_pipeline_rasterization_provoking_vertex_state_create_info_ext       = int(1000254001)
	structure_type_physical_device_provoking_vertex_properties_ext                     = int(1000254002)
	structure_type_surface_full_screen_exclusive_info_ext                              = int(1000255000)
	structure_type_surface_capabilities_full_screen_exclusive_ext                      = int(1000255002)
	structure_type_surface_full_screen_exclusive_win32_info_ext                        = int(1000255001)
	structure_type_headless_surface_create_info_ext                                    = int(1000256000)
	structure_type_physical_device_line_rasterization_features_ext                     = int(1000259000)
	structure_type_pipeline_rasterization_line_state_create_info_ext                   = int(1000259001)
	structure_type_physical_device_line_rasterization_properties_ext                   = int(1000259002)
	structure_type_physical_device_shader_atomic_float_features_ext                    = int(1000260000)
	structure_type_physical_device_index_type_uint8_features_ext                       = int(1000265000)
	structure_type_physical_device_extended_dynamic_state_features_ext                 = int(1000267000)
	structure_type_physical_device_pipeline_executable_properties_features_khr         = int(1000269000)
	structure_type_pipeline_info_khr                                                   = int(1000269001)
	structure_type_pipeline_executable_properties_khr                                  = int(1000269002)
	structure_type_pipeline_executable_info_khr                                        = int(1000269003)
	structure_type_pipeline_executable_statistic_khr                                   = int(1000269004)
	structure_type_pipeline_executable_internal_representation_khr                     = int(1000269005)
	structure_type_physical_device_host_image_copy_features_ext                        = int(1000270000)
	structure_type_physical_device_host_image_copy_properties_ext                      = int(1000270001)
	structure_type_memory_to_image_copy_ext                                            = int(1000270002)
	structure_type_image_to_memory_copy_ext                                            = int(1000270003)
	structure_type_copy_image_to_memory_info_ext                                       = int(1000270004)
	structure_type_copy_memory_to_image_info_ext                                       = int(1000270005)
	structure_type_host_image_layout_transition_info_ext                               = int(1000270006)
	structure_type_copy_image_to_image_info_ext                                        = int(1000270007)
	structure_type_subresource_host_memcpy_size_ext                                    = int(1000270008)
	structure_type_host_image_copy_device_performance_query_ext                        = int(1000270009)
	structure_type_memory_map_info_khr                                                 = int(1000271000)
	structure_type_memory_unmap_info_khr                                               = int(1000271001)
	structure_type_physical_device_shader_atomic_float_2_features_ext                  = int(1000273000)
	structure_type_surface_present_mode_ext                                            = int(1000274000)
	structure_type_surface_present_scaling_capabilities_ext                            = int(1000274001)
	structure_type_surface_present_mode_compatibility_ext                              = int(1000274002)
	structure_type_physical_device_swapchain_maintenance_1_features_ext                = int(1000275000)
	structure_type_swapchain_present_fence_info_ext                                    = int(1000275001)
	structure_type_swapchain_present_modes_create_info_ext                             = int(1000275002)
	structure_type_swapchain_present_mode_info_ext                                     = int(1000275003)
	structure_type_swapchain_present_scaling_create_info_ext                           = int(1000275004)
	structure_type_release_swapchain_images_info_ext                                   = int(1000275005)
	structure_type_physical_device_device_generated_commands_properties_nv             = int(1000277000)
	structure_type_graphics_shader_group_create_info_nv                                = int(1000277001)
	structure_type_graphics_pipeline_shader_groups_create_info_nv                      = int(1000277002)
	structure_type_indirect_commands_layout_token_nv                                   = int(1000277003)
	structure_type_indirect_commands_layout_create_info_nv                             = int(1000277004)
	structure_type_generated_commands_info_nv                                          = int(1000277005)
	structure_type_generated_commands_memory_requirements_info_nv                      = int(1000277006)
	structure_type_physical_device_device_generated_commands_features_nv               = int(1000277007)
	structure_type_physical_device_inherited_viewport_scissor_features_nv              = int(1000278000)
	structure_type_command_buffer_inheritance_viewport_scissor_info_nv                 = int(1000278001)
	structure_type_physical_device_texel_buffer_alignment_features_ext                 = int(1000281000)
	structure_type_command_buffer_inheritance_render_pass_transform_info_qcom          = int(1000282000)
	structure_type_render_pass_transform_begin_info_qcom                               = int(1000282001)
	structure_type_physical_device_depth_bias_control_features_ext                     = int(1000283000)
	structure_type_depth_bias_info_ext                                                 = int(1000283001)
	structure_type_depth_bias_representation_info_ext                                  = int(1000283002)
	structure_type_physical_device_device_memory_report_features_ext                   = int(1000284000)
	structure_type_device_device_memory_report_create_info_ext                         = int(1000284001)
	structure_type_device_memory_report_callback_data_ext                              = int(1000284002)
	structure_type_physical_device_robustness_2_features_ext                           = int(1000286000)
	structure_type_physical_device_robustness_2_properties_ext                         = int(1000286001)
	structure_type_sampler_custom_border_color_create_info_ext                         = int(1000287000)
	structure_type_physical_device_custom_border_color_properties_ext                  = int(1000287001)
	structure_type_physical_device_custom_border_color_features_ext                    = int(1000287002)
	structure_type_pipeline_library_create_info_khr                                    = int(1000290000)
	structure_type_physical_device_present_barrier_features_nv                         = int(1000292000)
	structure_type_surface_capabilities_present_barrier_nv                             = int(1000292001)
	structure_type_swapchain_present_barrier_create_info_nv                            = int(1000292002)
	structure_type_present_id_khr                                                      = int(1000294000)
	structure_type_physical_device_present_id_features_khr                             = int(1000294001)
	structure_type_physical_device_diagnostics_config_features_nv                      = int(1000300000)
	structure_type_device_diagnostics_config_create_info_nv                            = int(1000300001)
	structure_type_cuda_module_create_info_nv                                          = int(1000307000)
	structure_type_cuda_function_create_info_nv                                        = int(1000307001)
	structure_type_cuda_launch_info_nv                                                 = int(1000307002)
	structure_type_physical_device_cuda_kernel_launch_features_nv                      = int(1000307003)
	structure_type_physical_device_cuda_kernel_launch_properties_nv                    = int(1000307004)
	structure_type_query_low_latency_support_nv                                        = int(1000310000)
	structure_type_export_metal_object_create_info_ext                                 = int(1000311000)
	structure_type_export_metal_objects_info_ext                                       = int(1000311001)
	structure_type_export_metal_device_info_ext                                        = int(1000311002)
	structure_type_export_metal_command_queue_info_ext                                 = int(1000311003)
	structure_type_export_metal_buffer_info_ext                                        = int(1000311004)
	structure_type_import_metal_buffer_info_ext                                        = int(1000311005)
	structure_type_export_metal_texture_info_ext                                       = int(1000311006)
	structure_type_import_metal_texture_info_ext                                       = int(1000311007)
	structure_type_export_metal_io_surface_info_ext                                    = int(1000311008)
	structure_type_import_metal_io_surface_info_ext                                    = int(1000311009)
	structure_type_export_metal_shared_event_info_ext                                  = int(1000311010)
	structure_type_import_metal_shared_event_info_ext                                  = int(1000311011)
	structure_type_queue_family_checkpoint_properties_2_nv                             = int(1000314008)
	structure_type_checkpoint_data_2_nv                                                = int(1000314009)
	structure_type_physical_device_descriptor_buffer_properties_ext                    = int(1000316000)
	structure_type_physical_device_descriptor_buffer_density_map_properties_ext        = int(1000316001)
	structure_type_physical_device_descriptor_buffer_features_ext                      = int(1000316002)
	structure_type_descriptor_address_info_ext                                         = int(1000316003)
	structure_type_descriptor_get_info_ext                                             = int(1000316004)
	structure_type_buffer_capture_descriptor_data_info_ext                             = int(1000316005)
	structure_type_image_capture_descriptor_data_info_ext                              = int(1000316006)
	structure_type_image_view_capture_descriptor_data_info_ext                         = int(1000316007)
	structure_type_sampler_capture_descriptor_data_info_ext                            = int(1000316008)
	structure_type_opaque_capture_descriptor_data_create_info_ext                      = int(1000316010)
	structure_type_descriptor_buffer_binding_info_ext                                  = int(1000316011)
	structure_type_descriptor_buffer_binding_push_descriptor_buffer_handle_ext         = int(1000316012)
	structure_type_acceleration_structure_capture_descriptor_data_info_ext             = int(1000316009)
	structure_type_physical_device_graphics_pipeline_library_features_ext              = int(1000320000)
	structure_type_physical_device_graphics_pipeline_library_properties_ext            = int(1000320001)
	structure_type_graphics_pipeline_library_create_info_ext                           = int(1000320002)
	structure_type_physical_device_shader_early_and_late_fragment_tests_features_amd   = int(1000321000)
	structure_type_physical_device_fragment_shader_barycentric_features_khr            = int(1000203000)
	structure_type_physical_device_fragment_shader_barycentric_properties_khr          = int(1000322000)
	structure_type_physical_device_shader_subgroup_uniform_control_flow_features_khr   = int(1000323000)
	structure_type_physical_device_fragment_shading_rate_enums_properties_nv           = int(1000326000)
	structure_type_physical_device_fragment_shading_rate_enums_features_nv             = int(1000326001)
	structure_type_pipeline_fragment_shading_rate_enum_state_create_info_nv            = int(1000326002)
	structure_type_acceleration_structure_geometry_motion_triangles_data_nv            = int(1000327000)
	structure_type_physical_device_ray_tracing_motion_blur_features_nv                 = int(1000327001)
	structure_type_acceleration_structure_motion_info_nv                               = int(1000327002)
	structure_type_physical_device_mesh_shader_features_ext                            = int(1000328000)
	structure_type_physical_device_mesh_shader_properties_ext                          = int(1000328001)
	structure_type_physical_device_ycbcr_2_plane_444_formats_features_ext              = int(1000330000)
	structure_type_physical_device_fragment_density_map_2_features_ext                 = int(1000332000)
	structure_type_physical_device_fragment_density_map_2_properties_ext               = int(1000332001)
	structure_type_copy_command_transform_info_qcom                                    = int(1000333000)
	structure_type_physical_device_workgroup_memory_explicit_layout_features_khr       = int(1000336000)
	structure_type_physical_device_image_compression_control_features_ext              = int(1000338000)
	structure_type_image_compression_control_ext                                       = int(1000338001)
	structure_type_image_compression_properties_ext                                    = int(1000338004)
	structure_type_physical_device_attachment_feedback_loop_layout_features_ext        = int(1000339000)
	structure_type_physical_device_4444_formats_features_ext                           = int(1000340000)
	structure_type_physical_device_fault_features_ext                                  = int(1000341000)
	structure_type_device_fault_counts_ext                                             = int(1000341001)
	structure_type_device_fault_info_ext                                               = int(1000341002)
	structure_type_physical_device_rgba10x6_formats_features_ext                       = int(1000344000)
	structure_type_directfb_surface_create_info_ext                                    = int(1000346000)
	structure_type_physical_device_vertex_input_dynamic_state_features_ext             = int(1000352000)
	structure_type_vertex_input_binding_description_2_ext                              = int(1000352001)
	structure_type_vertex_input_attribute_description_2_ext                            = int(1000352002)
	structure_type_physical_device_drm_properties_ext                                  = int(1000353000)
	structure_type_physical_device_address_binding_report_features_ext                 = int(1000354000)
	structure_type_device_address_binding_callback_data_ext                            = int(1000354001)
	structure_type_physical_device_depth_clip_control_features_ext                     = int(1000355000)
	structure_type_pipeline_viewport_depth_clip_control_create_info_ext                = int(1000355001)
	structure_type_physical_device_primitive_topology_list_restart_features_ext        = int(1000356000)
	structure_type_import_memory_zircon_handle_info_fuchsia                            = int(1000364000)
	structure_type_memory_zircon_handle_properties_fuchsia                             = int(1000364001)
	structure_type_memory_get_zircon_handle_info_fuchsia                               = int(1000364002)
	structure_type_import_semaphore_zircon_handle_info_fuchsia                         = int(1000365000)
	structure_type_semaphore_get_zircon_handle_info_fuchsia                            = int(1000365001)
	structure_type_buffer_collection_create_info_fuchsia                               = int(1000366000)
	structure_type_import_memory_buffer_collection_fuchsia                             = int(1000366001)
	structure_type_buffer_collection_image_create_info_fuchsia                         = int(1000366002)
	structure_type_buffer_collection_properties_fuchsia                                = int(1000366003)
	structure_type_buffer_constraints_info_fuchsia                                     = int(1000366004)
	structure_type_buffer_collection_buffer_create_info_fuchsia                        = int(1000366005)
	structure_type_image_constraints_info_fuchsia                                      = int(1000366006)
	structure_type_image_format_constraints_info_fuchsia                               = int(1000366007)
	structure_type_sysmem_color_space_fuchsia                                          = int(1000366008)
	structure_type_buffer_collection_constraints_info_fuchsia                          = int(1000366009)
	structure_type_subpass_shading_pipeline_create_info_huawei                         = int(1000369000)
	structure_type_physical_device_subpass_shading_features_huawei                     = int(1000369001)
	structure_type_physical_device_subpass_shading_properties_huawei                   = int(1000369002)
	structure_type_physical_device_invocation_mask_features_huawei                     = int(1000370000)
	structure_type_memory_get_remote_address_info_nv                                   = int(1000371000)
	structure_type_physical_device_external_memory_rdma_features_nv                    = int(1000371001)
	structure_type_pipeline_properties_identifier_ext                                  = int(1000372000)
	structure_type_physical_device_pipeline_properties_features_ext                    = int(1000372001)
	structure_type_physical_device_frame_boundary_features_ext                         = int(1000375000)
	structure_type_frame_boundary_ext                                                  = int(1000375001)
	structure_type_physical_device_multisampled_render_to_single_sampled_features_ext  = int(1000376000)
	structure_type_subpass_resolve_performance_query_ext                               = int(1000376001)
	structure_type_multisampled_render_to_single_sampled_info_ext                      = int(1000376002)
	structure_type_physical_device_extended_dynamic_state_2_features_ext               = int(1000377000)
	structure_type_screen_surface_create_info_qnx                                      = int(1000378000)
	structure_type_physical_device_color_write_enable_features_ext                     = int(1000381000)
	structure_type_pipeline_color_write_create_info_ext                                = int(1000381001)
	structure_type_physical_device_primitives_generated_query_features_ext             = int(1000382000)
	structure_type_physical_device_ray_tracing_maintenance_1_features_khr              = int(1000386000)
	structure_type_physical_device_image_view_min_lod_features_ext                     = int(1000391000)
	structure_type_image_view_min_lod_create_info_ext                                  = int(1000391001)
	structure_type_physical_device_multi_draw_features_ext                             = int(1000392000)
	structure_type_physical_device_multi_draw_properties_ext                           = int(1000392001)
	structure_type_physical_device_image_2d_view_of_3d_features_ext                    = int(1000393000)
	structure_type_physical_device_shader_tile_image_features_ext                      = int(1000395000)
	structure_type_physical_device_shader_tile_image_properties_ext                    = int(1000395001)
	structure_type_micromap_build_info_ext                                             = int(1000396000)
	structure_type_micromap_version_info_ext                                           = int(1000396001)
	structure_type_copy_micromap_info_ext                                              = int(1000396002)
	structure_type_copy_micromap_to_memory_info_ext                                    = int(1000396003)
	structure_type_copy_memory_to_micromap_info_ext                                    = int(1000396004)
	structure_type_physical_device_opacity_micromap_features_ext                       = int(1000396005)
	structure_type_physical_device_opacity_micromap_properties_ext                     = int(1000396006)
	structure_type_micromap_create_info_ext                                            = int(1000396007)
	structure_type_micromap_build_sizes_info_ext                                       = int(1000396008)
	structure_type_acceleration_structure_triangles_opacity_micromap_ext               = int(1000396009)
	structure_type_physical_device_cluster_culling_shader_features_huawei              = int(1000404000)
	structure_type_physical_device_cluster_culling_shader_properties_huawei            = int(1000404001)
	structure_type_physical_device_cluster_culling_shader_vrs_features_huawei          = int(1000404002)
	structure_type_physical_device_border_color_swizzle_features_ext                   = int(1000411000)
	structure_type_sampler_border_color_component_mapping_create_info_ext              = int(1000411001)
	structure_type_physical_device_pageable_device_local_memory_features_ext           = int(1000412000)
	structure_type_physical_device_shader_core_properties_arm                          = int(1000415000)
	structure_type_device_queue_shader_core_control_create_info_arm                    = int(1000417000)
	structure_type_physical_device_scheduling_controls_features_arm                    = int(1000417001)
	structure_type_physical_device_scheduling_controls_properties_arm                  = int(1000417002)
	structure_type_physical_device_image_sliced_view_of_3d_features_ext                = int(1000418000)
	structure_type_image_view_sliced_create_info_ext                                   = int(1000418001)
	structure_type_physical_device_descriptor_set_host_mapping_features_valve          = int(1000420000)
	structure_type_descriptor_set_binding_reference_valve                              = int(1000420001)
	structure_type_descriptor_set_layout_host_mapping_info_valve                       = int(1000420002)
	structure_type_physical_device_depth_clamp_zero_one_features_ext                   = int(1000421000)
	structure_type_physical_device_non_seamless_cube_map_features_ext                  = int(1000422000)
	structure_type_physical_device_render_pass_striped_features_arm                    = int(1000424000)
	structure_type_physical_device_render_pass_striped_properties_arm                  = int(1000424001)
	structure_type_render_pass_stripe_begin_info_arm                                   = int(1000424002)
	structure_type_render_pass_stripe_info_arm                                         = int(1000424003)
	structure_type_render_pass_stripe_submit_info_arm                                  = int(1000424004)
	structure_type_physical_device_fragment_density_map_offset_features_qcom           = int(1000425000)
	structure_type_physical_device_fragment_density_map_offset_properties_qcom         = int(1000425001)
	structure_type_subpass_fragment_density_map_offset_end_info_qcom                   = int(1000425002)
	structure_type_physical_device_copy_memory_indirect_features_nv                    = int(1000426000)
	structure_type_physical_device_copy_memory_indirect_properties_nv                  = int(1000426001)
	structure_type_physical_device_memory_decompression_features_nv                    = int(1000427000)
	structure_type_physical_device_memory_decompression_properties_nv                  = int(1000427001)
	structure_type_physical_device_device_generated_commands_compute_features_nv       = int(1000428000)
	structure_type_compute_pipeline_indirect_buffer_info_nv                            = int(1000428001)
	structure_type_pipeline_indirect_device_address_info_nv                            = int(1000428002)
	structure_type_physical_device_linear_color_attachment_features_nv                 = int(1000430000)
	structure_type_physical_device_image_compression_control_swapchain_features_ext    = int(1000437000)
	structure_type_physical_device_image_processing_features_qcom                      = int(1000440000)
	structure_type_physical_device_image_processing_properties_qcom                    = int(1000440001)
	structure_type_image_view_sample_weight_create_info_qcom                           = int(1000440002)
	structure_type_physical_device_nested_command_buffer_features_ext                  = int(1000451000)
	structure_type_physical_device_nested_command_buffer_properties_ext                = int(1000451001)
	structure_type_external_memory_acquire_unmodified_ext                              = int(1000453000)
	structure_type_physical_device_extended_dynamic_state_3_features_ext               = int(1000455000)
	structure_type_physical_device_extended_dynamic_state_3_properties_ext             = int(1000455001)
	structure_type_physical_device_subpass_merge_feedback_features_ext                 = int(1000458000)
	structure_type_render_pass_creation_control_ext                                    = int(1000458001)
	structure_type_render_pass_creation_feedback_create_info_ext                       = int(1000458002)
	structure_type_render_pass_subpass_feedback_create_info_ext                        = int(1000458003)
	structure_type_direct_driver_loading_info_lunarg                                   = int(1000459000)
	structure_type_direct_driver_loading_list_lunarg                                   = int(1000459001)
	structure_type_physical_device_shader_module_identifier_features_ext               = int(1000462000)
	structure_type_physical_device_shader_module_identifier_properties_ext             = int(1000462001)
	structure_type_pipeline_shader_stage_module_identifier_create_info_ext             = int(1000462002)
	structure_type_shader_module_identifier_ext                                        = int(1000462003)
	structure_type_physical_device_rasterization_order_attachment_access_features_ext  = int(1000342000)
	structure_type_physical_device_optical_flow_features_nv                            = int(1000464000)
	structure_type_physical_device_optical_flow_properties_nv                          = int(1000464001)
	structure_type_optical_flow_image_format_info_nv                                   = int(1000464002)
	structure_type_optical_flow_image_format_properties_nv                             = int(1000464003)
	structure_type_optical_flow_session_create_info_nv                                 = int(1000464004)
	structure_type_optical_flow_execute_info_nv                                        = int(1000464005)
	structure_type_optical_flow_session_create_private_data_info_nv                    = int(1000464010)
	structure_type_physical_device_legacy_dithering_features_ext                       = int(1000465000)
	structure_type_physical_device_pipeline_protected_access_features_ext              = int(1000466000)
	structure_type_physical_device_external_format_resolve_features_android            = int(1000468000)
	structure_type_physical_device_external_format_resolve_properties_android          = int(1000468001)
	structure_type_android_hardware_buffer_format_resolve_properties_android           = int(1000468002)
	structure_type_physical_device_maintenance_5_features_khr                          = int(1000470000)
	structure_type_physical_device_maintenance_5_properties_khr                        = int(1000470001)
	structure_type_rendering_area_info_khr                                             = int(1000470003)
	structure_type_device_image_subresource_info_khr                                   = int(1000470004)
	structure_type_subresource_layout_2_khr                                            = int(1000338002)
	structure_type_image_subresource_2_khr                                             = int(1000338003)
	structure_type_pipeline_create_flags_2_create_info_khr                             = int(1000470005)
	structure_type_buffer_usage_flags_2_create_info_khr                                = int(1000470006)
	structure_type_physical_device_ray_tracing_position_fetch_features_khr             = int(1000481000)
	structure_type_physical_device_shader_object_features_ext                          = int(1000482000)
	structure_type_physical_device_shader_object_properties_ext                        = int(1000482001)
	structure_type_shader_create_info_ext                                              = int(1000482002)
	structure_type_physical_device_tile_properties_features_qcom                       = int(1000484000)
	structure_type_tile_properties_qcom                                                = int(1000484001)
	structure_type_physical_device_amigo_profiling_features_sec                        = int(1000485000)
	structure_type_amigo_profiling_submit_info_sec                                     = int(1000485001)
	structure_type_physical_device_multiview_per_view_viewports_features_qcom          = int(1000488000)
	structure_type_physical_device_ray_tracing_invocation_reorder_features_nv          = int(1000490000)
	structure_type_physical_device_ray_tracing_invocation_reorder_properties_nv        = int(1000490001)
	structure_type_physical_device_extended_sparse_address_space_features_nv           = int(1000492000)
	structure_type_physical_device_extended_sparse_address_space_properties_nv         = int(1000492001)
	structure_type_physical_device_mutable_descriptor_type_features_ext                = int(1000351000)
	structure_type_mutable_descriptor_type_create_info_ext                             = int(1000351002)
	structure_type_layer_settings_create_info_ext                                      = int(1000496000)
	structure_type_physical_device_shader_core_builtins_features_arm                   = int(1000497000)
	structure_type_physical_device_shader_core_builtins_properties_arm                 = int(1000497001)
	structure_type_physical_device_pipeline_library_group_handles_features_ext         = int(1000498000)
	structure_type_physical_device_dynamic_rendering_unused_attachments_features_ext   = int(1000499000)
	structure_type_latency_sleep_mode_info_nv                                          = int(1000505000)
	structure_type_latency_sleep_info_nv                                               = int(1000505001)
	structure_type_set_latency_marker_info_nv                                          = int(1000505002)
	structure_type_get_latency_marker_info_nv                                          = int(1000505003)
	structure_type_latency_timings_frame_report_nv                                     = int(1000505004)
	structure_type_latency_submission_present_id_nv                                    = int(1000505005)
	structure_type_out_of_band_queue_type_info_nv                                      = int(1000505006)
	structure_type_swapchain_latency_create_info_nv                                    = int(1000505007)
	structure_type_latency_surface_capabilities_nv                                     = int(1000505008)
	structure_type_physical_device_cooperative_matrix_features_khr                     = int(1000506000)
	structure_type_cooperative_matrix_properties_khr                                   = int(1000506001)
	structure_type_physical_device_cooperative_matrix_properties_khr                   = int(1000506002)
	structure_type_physical_device_multiview_per_view_render_areas_features_qcom       = int(1000510000)
	structure_type_multiview_per_view_render_areas_render_pass_begin_info_qcom         = int(1000510001)
	structure_type_physical_device_image_processing_2_features_qcom                    = int(1000518000)
	structure_type_physical_device_image_processing_2_properties_qcom                  = int(1000518001)
	structure_type_sampler_block_match_window_create_info_qcom                         = int(1000518002)
	structure_type_sampler_cubic_weights_create_info_qcom                              = int(1000519000)
	structure_type_physical_device_cubic_weights_features_qcom                         = int(1000519001)
	structure_type_blit_image_cubic_weights_info_qcom                                  = int(1000519002)
	structure_type_physical_device_ycbcr_degamma_features_qcom                         = int(1000520000)
	structure_type_sampler_ycbcr_conversion_ycbcr_degamma_create_info_qcom             = int(1000520001)
	structure_type_physical_device_cubic_clamp_features_qcom                           = int(1000521000)
	structure_type_physical_device_attachment_feedback_loop_dynamic_state_features_ext = int(1000524000)
	structure_type_screen_buffer_properties_qnx                                        = int(1000529000)
	structure_type_screen_buffer_format_properties_qnx                                 = int(1000529001)
	structure_type_import_screen_buffer_info_qnx                                       = int(1000529002)
	structure_type_external_format_qnx                                                 = int(1000529003)
	structure_type_physical_device_external_memory_screen_buffer_features_qnx          = int(1000529004)
	structure_type_physical_device_layered_driver_properties_msft                      = int(1000530000)
	structure_type_physical_device_descriptor_pool_overallocation_features_nv          = int(1000546000)
	structure_type_max_enum                                                            = int(0x7FFFFFFF)
}

pub enum Result {
	success                                            = int(0)
	not_ready                                          = int(1)
	timeout                                            = int(2)
	event_set                                          = int(3)
	event_reset                                        = int(4)
	incomplete                                         = int(5)
	error_out_of_host_memory                           = int(-1)
	error_out_of_device_memory                         = int(-2)
	error_initialization_failed                        = int(-3)
	error_device_lost                                  = int(-4)
	error_memory_map_failed                            = int(-5)
	error_layer_not_present                            = int(-6)
	error_extension_not_present                        = int(-7)
	error_feature_not_present                          = int(-8)
	error_incompatible_driver                          = int(-9)
	error_too_many_objects                             = int(-10)
	error_format_not_supported                         = int(-11)
	error_fragmented_pool                              = int(-12)
	error_unknown                                      = int(-13)
	error_out_of_pool_memory                           = int(-1000069000)
	error_invalid_external_handle                      = int(-1000072003)
	error_fragmentation                                = int(-1000161000)
	error_invalid_opaque_capture_address               = int(-1000257000)
	pipeline_compile_required                          = int(1000297000)
	error_surface_lost_khr                             = int(-1000000000)
	error_native_window_in_use_khr                     = int(-1000000001)
	suboptimal_khr                                     = int(1000001003)
	error_out_of_date_khr                              = int(-1000001004)
	error_incompatible_display_khr                     = int(-1000003001)
	error_validation_failed_ext                        = int(-1000011001)
	error_invalid_shader_nv                            = int(-1000012000)
	error_image_usage_not_supported_khr                = int(-1000023000)
	error_video_picture_layout_not_supported_khr       = int(-1000023001)
	error_video_profile_operation_not_supported_khr    = int(-1000023002)
	error_video_profile_format_not_supported_khr       = int(-1000023003)
	error_video_profile_codec_not_supported_khr        = int(-1000023004)
	error_video_std_version_not_supported_khr          = int(-1000023005)
	error_invalid_drm_format_modifier_plane_layout_ext = int(-1000158000)
	error_not_permitted_khr                            = int(-1000174001)
	error_full_screen_exclusive_mode_lost_ext          = int(-1000255000)
	thread_idle_khr                                    = int(1000268000)
	thread_done_khr                                    = int(1000268001)
	operation_deferred_khr                             = int(1000268002)
	operation_not_deferred_khr                         = int(1000268003)
	error_compression_exhausted_ext                    = int(-1000338000)
	error_incompatible_shader_binary_ext               = int(1000482000)
	result_max_enum                                    = int(0x7FFFFFFF)
}

pub type C.Instance = voidptr

pub type C.PhysicalDevice = voidptr
pub type Bool32 = u32

// type VkEnumeratePhysicalDevices = fn (C.Instance, &u32, []&C.PhysicalDevice) Result
// type C.VkEnumeratePhysicalDevices = fn (&C.Instance, &u32, voidptr) Result

fn C.vkEnumeratePhysicalDevices(&C.Instance, &u32, []&C.PhysicalDevice) Result

// pub type PhysicalDevices = []&C.PhysicalDevice | voidptr

pub fn enumerate_physical_devices(instance &C.Instance, p_physical_device_count &u32, p_physical_devices voidptr) Result {
	return C.vkEnumeratePhysicalDevices(instance, p_physical_device_count, p_physical_devices)
}

pub struct PhysicalDeviceFeatures {
pub mut:
	robust_buffer_access                         Bool32
	full_draw_index_uint32                       Bool32
	image_cube_array                             Bool32
	independent_blend                            Bool32
	geometry_shader                              Bool32
	tessellation_shader                          Bool32
	sample_rate_shading                          Bool32
	dual_src_blend                               Bool32
	logic_op                                     Bool32
	multi_draw_indirect                          Bool32
	draw_indirect_first_instance                 Bool32
	depth_clamp                                  Bool32
	depth_bias_clamp                             Bool32
	fill_mode_non_solid                          Bool32
	depth_bounds                                 Bool32
	wide_lines                                   Bool32
	large_points                                 Bool32
	alpha_to_one                                 Bool32
	multi_viewport                               Bool32
	sampler_anisotropy                           Bool32
	texture_compression_etc2                     Bool32
	texture_compression_astc_ldr                 Bool32
	texture_compression_bc                       Bool32
	occlusion_query_precise                      Bool32
	pipeline_statistics_query                    Bool32
	vertex_pipeline_stores_and_atomics           Bool32
	fragment_stores_and_atomics                  Bool32
	shader_tessellation_and_geometry_point_size  Bool32
	shader_image_gather_extended                 Bool32
	shader_storage_image_extended_formats        Bool32
	shader_storage_image_multisample             Bool32
	shader_storage_image_read_without_format     Bool32
	shader_storage_image_write_without_format    Bool32
	shader_uniform_buffer_array_dynamic_indexing Bool32
	shader_sampled_image_array_dynamic_indexing  Bool32
	shader_storage_buffer_array_dynamic_indexing Bool32
	shader_storage_image_array_dynamic_indexing  Bool32
	shader_clip_distance                         Bool32
	shader_cull_distance                         Bool32
	shader_float64                               Bool32
	shader_int64                                 Bool32
	shader_int16                                 Bool32
	shader_resource_residency                    Bool32
	shader_resource_min_lod                      Bool32
	sparse_binding                               Bool32
	sparse_residency_buffer                      Bool32
	sparse_residency_image2_d                    Bool32
	sparse_residency_image3_d                    Bool32
	sparse_residency2_samples                    Bool32
	sparse_residency4_samples                    Bool32
	sparse_residency8_samples                    Bool32
	sparse_residency16_samples                   Bool32
	sparse_residency_aliased                     Bool32
	variable_multisample_rate                    Bool32
	inherited_queries                            Bool32
}

fn C.vkCreateInstance(&InstanceCreateInfo, &AllocationCallbacks, &C.Instance) Result
pub fn create_instance(p_create_info &InstanceCreateInfo, p_allocator &AllocationCallbacks, p_instance &C.Instance) Result {
	return C.vkCreateInstance(p_create_info, p_allocator, p_instance)
}

pub type PFN_vkAllocationFunction = fn (pUserData voidptr, size usize, alignment usize, allocationScope SystemAllocationScope) voidptr

pub type PFN_vkFreeFunction = fn (pUserData voidptr, pMemory voidptr) voidptr

pub type PFN_vkInternalAllocationNotification = fn (pUserData voidptr, size usize, allocationType InternalAllocationType, allocationScope SystemAllocationScope) voidptr

pub type PFN_vkInternalFreeNotification = fn (pUserData voidptr, size usize, allocationType InternalAllocationType, allocationScope SystemAllocationScope) voidptr

pub type PFN_vkReallocationFunction = fn (pUserData voidptr, pOriginal voidptr, size usize, alignment usize, allocationScope SystemAllocationScope) voidptr

pub type PFN_vkVoidFunction = fn ()

pub struct AllocationCallbacks {
pub mut:
	p_user_data             voidptr
	pfn_allocation          PFN_vkAllocationFunction   = unsafe { nil }
	pfn_reallocation        PFN_vkReallocationFunction = unsafe { nil }
	pfn_free                PFN_vkFreeFunction = unsafe { nil }
	pfn_internal_allocation PFN_vkInternalAllocationNotification = unsafe { nil }
	pfn_internal_free       PFN_vkInternalFreeNotification       = unsafe { nil }
}

pub enum SystemAllocationScope {
	system_allocation_scope_command  = int(0)
	system_allocation_scope_object   = int(1)
	system_allocation_scope_cache    = int(2)
	system_allocation_scope_device   = int(3)
	system_allocation_scope_instance = int(4)
	system_allocation_scope_max_enum = int(0x7FFFFFFF)
}

pub enum InternalAllocationType {
	internal_allocation_type_executable = int(0)
	internal_allocation_type_max_enum   = int(0x7FFFFFFF)
}

pub struct PhysicalDeviceProperties {
pub mut:
	api_version         u32
	driver_version      u32
	vendor_id           u32
	device_id           u32
	device_type         PhysicalDeviceType
	device_name         [256]char
	pipeline_cache_uuid [16]u8
	limits              PhysicalDeviceLimits
	sparse_properties   PhysicalDeviceSparseProperties
}

pub enum PhysicalDeviceType {
	physical_device_type_other          = int(0)
	physical_device_type_integrated_gpu = int(1)
	physical_device_type_discrete_gpu   = int(2)
	physical_device_type_virtual_gpu    = int(3)
	physical_device_type_cpu            = int(4)
	physical_device_type_max_enum       = int(0x7FFFFFFF)
}

pub struct PhysicalDeviceLimits {
pub mut:
	max_image_dimension1_d                                u32
	max_image_dimension2_d                                u32
	max_image_dimension3_d                                u32
	max_image_dimension_cube                              u32
	max_image_array_layers                                u32
	max_texel_buffer_elements                             u32
	max_uniform_buffer_range                              u32
	max_storage_buffer_range                              u32
	max_push_constants_size                               u32
	max_memory_allocation_count                           u32
	max_sampler_allocation_count                          u32
	buffer_image_granularity                              DeviceSize
	sparse_address_space_size                             DeviceSize
	max_bound_descriptor_sets                             u32
	max_per_stage_descriptor_samplers                     u32
	max_per_stage_descriptor_uniform_buffers              u32
	max_per_stage_descriptor_storage_buffers              u32
	max_per_stage_descriptor_sampled_images               u32
	max_per_stage_descriptor_storage_images               u32
	max_per_stage_descriptor_input_attachments            u32
	max_per_stage_resources                               u32
	max_descriptor_set_samplers                           u32
	max_descriptor_set_uniform_buffers                    u32
	max_descriptor_set_uniform_buffers_dynamic            u32
	max_descriptor_set_storage_buffers                    u32
	max_descriptor_set_storage_buffers_dynamic            u32
	max_descriptor_set_sampled_images                     u32
	max_descriptor_set_storage_images                     u32
	max_descriptor_set_input_attachments                  u32
	max_vertex_input_attributes                           u32
	max_vertex_input_bindings                             u32
	max_vertex_input_attribute_offset                     u32
	max_vertex_input_binding_stride                       u32
	max_vertex_output_components                          u32
	max_tessellation_generation_level                     u32
	max_tessellation_patch_size                           u32
	max_tessellation_control_per_vertex_input_components  u32
	max_tessellation_control_per_vertex_output_components u32
	max_tessellation_control_per_patch_output_components  u32
	max_tessellation_control_total_output_components      u32
	max_tessellation_evaluation_input_components          u32
	max_tessellation_evaluation_output_components         u32
	max_geometry_shader_invocations                       u32
	max_geometry_input_components                         u32
	max_geometry_output_components                        u32
	max_geometry_output_vertices                          u32
	max_geometry_total_output_components                  u32
	max_fragment_input_components                         u32
	max_fragment_output_attachments                       u32
	max_fragment_dual_src_attachments                     u32
	max_fragment_combined_output_resources                u32
	max_compute_shared_memory_size                        u32
	max_compute_work_group_count                          [3]u32
	max_compute_work_group_invocations                    u32
	max_compute_work_group_size                           [3]u32
	sub_pixel_precision_bits                              u32
	sub_texel_precision_bits                              u32
	mipmap_precision_bits                                 u32
	max_draw_indexed_index_value                          u32
	max_draw_indirect_count                               u32
	max_sampler_lod_bias                                  f32
	max_sampler_anisotropy                                f32
	max_viewports                                         u32
	max_viewport_dimensions                               [2]u32
	viewport_bounds_range                                 [2]f32
	viewport_sub_pixel_bits                               u32
	min_memory_map_alignment                              usize
	min_texel_buffer_offset_alignment                     DeviceSize
	min_uniform_buffer_offset_alignment                   DeviceSize
	min_storage_buffer_offset_alignment                   DeviceSize
	min_texel_offset                                      i32
	max_texel_offset                                      u32
	min_texel_gather_offset                               i32
	max_texel_gather_offset                               u32
	min_interpolation_offset                              f32
	max_interpolation_offset                              f32
	sub_pixel_interpolation_offset_bits                   u32
	max_framebuffer_width                                 u32
	max_framebuffer_height                                u32
	max_framebuffer_layers                                u32
	framebuffer_color_sample_counts                       SampleCountFlags
	framebuffer_depth_sample_counts                       SampleCountFlags
	framebuffer_stencil_sample_counts                     SampleCountFlags
	framebuffer_no_attachments_sample_counts              SampleCountFlags
	max_color_attachments                                 u32
	sampled_image_color_sample_counts                     SampleCountFlags
	sampled_image_integer_sample_counts                   SampleCountFlags
	sampled_image_depth_sample_counts                     SampleCountFlags
	sampled_image_stencil_sample_counts                   SampleCountFlags
	storage_image_sample_counts                           SampleCountFlags
	max_sample_mask_words                                 u32
	timestamp_compute_and_graphics                        Bool32
	timestamp_period                                      f32
	max_clip_distances                                    u32
	max_cull_distances                                    u32
	max_combined_clip_and_cull_distances                  u32
	discrete_queue_priorities                             u32
	point_size_range                                      [2]f32
	line_width_range                                      [2]f32
	point_size_granularity                                f32
	line_width_granularity                                f32
	strict_lines                                          Bool32
	standard_sample_locations                             Bool32
	optimal_buffer_copy_offset_alignment                  DeviceSize
	optimal_buffer_copy_row_pitch_alignment               DeviceSize
	non_coherent_atom_size                                DeviceSize
}

pub type DeviceSize = u64

pub type SampleCountFlags = u32

pub struct PhysicalDeviceSparseProperties {
pub mut:
	residency_standard2_d_block_shape             Bool32
	residency_standard2_d_multisample_block_shape Bool32
	residency_standard3_d_block_shape             Bool32
	residency_aligned_mip_size                    Bool32
	residency_non_resident_strict                 Bool32
}

fn C.vkGetPhysicalDeviceProperties(C.PhysicalDevice, &PhysicalDeviceProperties)
pub fn get_physical_device_properties(physical_device C.PhysicalDevice, p_properties &PhysicalDeviceProperties) {
	C.vkGetPhysicalDeviceProperties(physical_device, p_properties)
}
