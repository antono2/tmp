module main

import vulkan as vk

#flag linux -L/usr/lib/x86_64-linux-gnu
#flag linux -lglfw
#flag linux -DGLFW_INCLUDE_VULKAN=1

//#flag linux -I/usr/include
#flag linux -lvulkan

#include "GLFW/glfw3.h"

pub const glfw_true = 1
pub const glfw_press = 1 << 0
pub const glfw_key_enter = 257
pub const glfw_key_escape = 256

@[heap]
struct App {
pub mut:
	main_window &C.GLFWwindow
	share_data  []string // some data to share between callback and main()
}

fn init_app(window &C.GLFWwindow) App {
	new_app := App{
		main_window: unsafe { window }
		share_data: []
	}
	return new_app
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
	window = glfw_create_window_desc(960, 480, 'Using a window in 2024 LOL', mut monitor, mut
		window)

	mut app := init_app(window)

	// set user pointer to &App
	glfw_set_user_pointer(window, &app)
	// set callback function for keyboard input
	glfw_set_key_callback(window, key_callback_function)
	glfw_make_context_current(window)

	if !glfw_is_vulkan_supported() {
		panic('Vulkan is not available')
	}

	create_info := vk.InstanceCreateInfo{
		s_type: vk.StructureType.structure_type_instance_create_info
		flags: 0
		p_application_info: &vk.ApplicationInfo{
			p_application_name: c'Vulkan in Vlang'
			p_engine_name: c'This is not an Engine... yet'
			api_version: vk.header_version_complete
		}
		// TODO: VK_KHR_surface extension for glfw
		pp_enabled_layer_names: unsafe { nil }
		enabled_layer_count: 0
		pp_enabled_extension_names: unsafe { nil }
		enabled_extension_count: 0
	}
	result := vk.create_instance(create_info, unsafe { nil }, &instance)

	// Note: You can use string_VkResult in /usr/include/vulkan/generated/vk_enum_string_helper.h
	// otherwise the string value of ${result} will just be the enum name, eg. 'success'
	if result != vk.Result.success {
		println("Couldn't create vulkan instance. VkResult: ${result}")
	}

	mut physical_device_cnt := u32(0)
	vk.enumerate_physical_devices(instance, &physical_device_cnt, unsafe { nil })
	if physical_device_cnt == 0 {
		panic("Couldn't find GPUs with vulkan support")
	}
	mut devices_c := create_c_array[C.PhysicalDevice](physical_device_cnt)
	if vk.enumerate_physical_devices(instance, &physical_device_cnt, devices_c) != vk.Result.success {
		panic("Couldn't enumerate physical devices")
	}
	devices := to_v_array[C.PhysicalDevice](devices_c, physical_device_cnt)
	for i in 0 .. physical_device_cnt {
		if is_device_suitable(devices[i]) {
			println('found device')
		}
	}

	// TODO update layers required for glfw on create_instance and use this too
	// glfw.get_physical_device_presentation_support(instance, ... )

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
fn key_callback_function(window &C.GLFWwindow, key int, scancode int, action int, mods int) {
	if action == glfw_press {
		// transfer the data to the app struct
		mut app := unsafe { &App(glfw_get_user_pointer(window)) }
		if key == glfw_key_enter {
			// if enter key pressed
			txt := 'Enter key pressed'
			app.share_data << txt
		}
		if key == glfw_key_escape {
			unsafe { glfw_set_should_close(window, 1) }
		}
	}
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

// Note: Using heap, since window also contains a pointer to user data,
// which shouldn't be cleaned up
@[heap; typedef]
struct C.GLFWwindow {
}

// Note: No need to use heap here, I think
@[typedef]
struct C.GLFWmonitor {
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
pub fn glfw_create_window_desc(width int, height int, title string, mut monitor C.GLFWmonitor, mut window C.GLFWwindow) &C.GLFWwindow {
	ret := C.glfwCreateWindow(width, height, title.str, monitor, window)
	return ret
}

fn C.glfwSetWindowUserPointer(window &C.GLFWwindow, pointer voidptr)
pub fn glfw_set_user_pointer(window &C.GLFWwindow, pointer voidptr) {
	C.glfwSetWindowUserPointer(window, pointer)
}

fn C.glfwGetWindowUserPointer(window &C.GLFWwindow) voidptr
pub fn glfw_get_user_pointer(window &C.GLFWwindow) voidptr {
	return C.glfwGetWindowUserPointer(window)
}

pub type GLFWFnKey = fn (window &C.GLFWwindow, key_id int, scan_code int, action int, bit_filed int)

fn C.glfwSetKeyCallback(window &C.GLFWwindow, callback GLFWFnKey)
pub fn glfw_set_key_callback(window &C.GLFWwindow, callback GLFWFnKey) {
	C.glfwSetKeyCallback(window, callback)
}

fn C.glfwMakeContextCurrent(window &C.GLFWwindow)
pub fn glfw_make_context_current(window &C.GLFWwindow) {
	C.glfwMakeContextCurrent(window)
}

fn C.glfwVulkanSupported() int
pub fn glfw_is_vulkan_supported() bool {
	return C.glfwVulkanSupported() == glfw_true
}

fn C.glfwSetWindowShouldClose(window &C.GLFWwindow, value int)
pub fn glfw_set_should_close(window &C.GLFWwindow, flag int) {
	C.glfwSetWindowShouldClose(window, flag)
}

fn C.glfwWindowShouldClose(window &C.GLFWwindow) int
pub fn glfw_window_should_close(window &C.GLFWwindow) bool {
	return C.glfwWindowShouldClose(window) == glfw_true
}

fn C.glfwPollEvents()
pub fn glfw_poll_events() {
	C.glfwPollEvents()
}

fn is_device_suitable(device &C.PhysicalDevice) bool {
	device_properties := vk.PhysicalDeviceProperties{}
	vk.get_physical_device_properties(device, device_properties)
	return device_properties.device_type == vk.PhysicalDeviceType.physical_device_type_discrete_gpu
}
