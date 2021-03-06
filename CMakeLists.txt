cmake_minimum_required(VERSION 2.8)

project(color_goded)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE RELEASE)
endif()

# Shut up the warning about CMake policy CMP0042.
if(APPLE)
  set(CMAKE_MACOSX_RPATH ON)
endif()

if(CMAKE_SIZEOF_VOID_P EQUAL 4)
  message(STATUS "Found 32bit system")
  set(64_BIT_PLATFORM 0)
else()
  message(STATUS "Found 64bit system")
  set(64_BIT_PLATFORM 1)
endif()

# Add custom find modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

# Submodules
message(STATUS "Updating submodules")
execute_process(
  COMMAND git submodule update --recursive --init
  WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
)

# C++14
include(cmake/cxx14.cmake)

# Boost
include(cmake/boost.cmake)

# Lua
include(cmake/lua.cmake)

# Curses
find_package(Curses REQUIRED)

# ZLib
find_package(ZLIB REQUIRED)

# PThread
find_package(Threads REQUIRED)


set(CG_GOPKG "$ENV{GOPATH}/pkg/darwin_amd64/github.com/richardsamuels")
set(CG_CPP_INC ${CMAKE_CURRENT_LIST_DIR}/include)

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/gobuild)

include_directories(
  include
  ${LLVM_INCLUDE_DIRS}

  ${CURSES_INCLUDE_PATH}
  ${ZLIB_INCLUDE_PATH}

  $ENV{PWD}/include/
  ${CG_GO_INC}
)

# Allow easier dynamic linking with clang
#set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
#set(CMAKE_INSTALL_RPATH ${LLVM_LIB_PATH})


include(cmake/generate_sources.cmake)
include(cmake/check_luajit.cmake)
add_library(${PROJECT_NAME} SHARED src/main.cpp src/golang.cpp)
add_custom_target(${PROJECT_NAME}_track_api
  COMMAND ${CMAKE_CURRENT_LIST_DIR}/lib/track_api
  WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
)
add_dependencies(${PROJECT_NAME} ${PROJECT_NAME}_track_api color_goded_ast.a)

# Force the same naming across platforms
set_property(TARGET ${PROJECT_NAME} PROPERTY PREFIX "")
set_property(TARGET ${PROJECT_NAME} PROPERTY OUTPUT_NAME "${PROJECT_NAME}.so")
set_property(TARGET ${PROJECT_NAME} PROPERTY SUFFIX "")


# Enable warnings
set(WARNING_FLAGS
    "-Wall -Wextra -pedantic -Wno-missing-field-initializers -Wno-unused-variable -Wno-deprecated-declarations -Wno-unused-parameter"
)
set_property(TARGET ${PROJECT_NAME} PROPERTY COMPILE_FLAGS ${WARNING_FLAGS})

# Fix compilation problem: relocation R_X86_64_32 against `a local symbol' can not be
# used when making a shared object; recompile with -fPIC.
# See http://www.cmake.org/pipermail/cmake/2007-May/014350.html
if(64_BIT_PLATFORM)
  set_property(TARGET ${PROJECT_NAME}_boost PROPERTY COMPILE_FLAGS "-fPIC")
endif()

target_link_libraries(${PROJECT_NAME}
  ${PROJECT_NAME}_boost
  ${COLOR_GODED}
  ${CG_GO_A}
  ${LUA_LIBRARIES}
  ${CURSES_LIBRARY}
  ${ZLIB_LIBRARIES}
  ${CMAKE_THREAD_LIBS_INIT}
)

# Install locally
set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_LIST_DIR})
install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_CURRENT_LIST_DIR})
