# Platform-neutral scrcpy protocol and frame utilities (C++17, no OS headers).
#
# Consumed by windows/scrcpy_stream. Tests build with any compiler:
#   macOS / Linux: scripts/test_native_core.sh
#   Windows:       cmake -S native/scrcpy_core -B build/core -DSCRCPY_CORE_BUILD_TESTS=ON
#                  cmake --build build/core && ctest --test-dir build/core
cmake_minimum_required(VERSION 3.14)
project(scrcpy_core LANGUAGES CXX)

option(SCRCPY_CORE_BUILD_TESTS "Build scrcpy_core unit tests" OFF)

add_library(scrcpy_core STATIC
  src/config_packet_merger.cpp
  src/latest_frame_buffer.cpp
  src/nv12_converter.cpp
  src/packet_header.cpp
  src/stream_header.cpp
)
target_include_directories(scrcpy_core PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_compile_features(scrcpy_core PUBLIC cxx_std_17)
set_target_properties(scrcpy_core PROPERTIES POSITION_INDEPENDENT_CODE ON)

if(MSVC)
  target_compile_options(scrcpy_core PRIVATE /W4 /WX)
else()
  target_compile_options(scrcpy_core PRIVATE
    -Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wshadow -Werror)
endif()

if(SCRCPY_CORE_BUILD_TESTS)
  enable_testing()
  find_package(Threads REQUIRED)
  add_executable(scrcpy_core_tests
    test/frame_test.cpp
    test/protocol_test.cpp
    test/test_main.cpp
  )
  target_link_libraries(scrcpy_core_tests PRIVATE scrcpy_core Threads::Threads)
  add_test(NAME scrcpy_core_tests COMMAND scrcpy_core_tests)
endif()
