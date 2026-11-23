cmake_minimum_required(VERSION 3.20)
project(OpenGLSuperBible4 LANGUAGES C CXX)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

# The OpenGL extension loader. GLee 5.21 is vendored in examples/src/shared and is the only loader the demos have been
# built with; the cache variable is the place to add another one (the demos use GLee's GLEE_* macros).
set(SB4_LOADER "GLEE" CACHE STRING "OpenGL extension loader: GLEE")
set_property(CACHE SB4_LOADER PROPERTY STRINGS GLEE)
if(NOT SB4_LOADER STREQUAL "GLEE")
  message(FATAL_ERROR "SB4_LOADER=${SB4_LOADER} is not implemented; the only loader is GLEE")
endif()

# GLUT. Linux and macOS use the system library (freeglut / the GLUT framework). Windows has no system GLUT, so
# freeglut is built from source as a static library; SB4_FETCH_FREEGLUT=ON does the same on any platform.
option(SB4_FETCH_FREEGLUT "Build freeglut from source instead of using the system GLUT" ${WIN32})

# The demos are OpenGL 2.1 compatibility code and call ARB entry points that only libGL exports, not GLVND's
# libOpenGL; prefer libGL, as the old Makefiles' -lGL did.
set(OpenGL_GL_PREFERENCE LEGACY)
find_package(OpenGL REQUIRED)

if(SB4_FETCH_FREEGLUT)
  include(FetchContent)
  set(FREEGLUT_BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
  set(FREEGLUT_BUILD_STATIC_LIBS ON CACHE BOOL "" FORCE)
  set(FREEGLUT_BUILD_DEMOS OFF CACHE BOOL "" FORCE)
  set(CMAKE_POLICY_VERSION_MINIMUM 3.5)
  FetchContent_Declare(freeglut
    URL https://github.com/FreeGLUTProject/freeglut/archive/refs/tags/v3.8.0.tar.gz)
  FetchContent_MakeAvailable(freeglut)
  add_library(sb4_glut INTERFACE)
  target_link_libraries(sb4_glut INTERFACE freeglut_static)
  target_include_directories(sb4_glut INTERFACE "${freeglut_SOURCE_DIR}/include" "${freeglut_SOURCE_DIR}/include/GL")
  target_compile_definitions(sb4_glut INTERFACE FREEGLUT_STATIC)
else()
  find_package(GLUT REQUIRED)
  add_library(sb4_glut INTERFACE)
  target_link_libraries(sb4_glut INTERFACE GLUT::GLUT)
  if(NOT APPLE AND GLUT_INCLUDE_DIR AND EXISTS "${GLUT_INCLUDE_DIR}/GL/glut.h")
    # gltools.h includes the bare <glut.h>; the old Makefiles passed -I/usr/include/GL.
    target_include_directories(sb4_glut INTERFACE "${GLUT_INCLUDE_DIR}/GL")
  endif()
endif()

if(APPLE)
  add_compile_definitions(GL_SILENCE_DEPRECATION)
elseif(MSVC)
  add_compile_definitions(_CRT_SECURE_NO_WARNINGS NOMINMAX)
endif()

add_subdirectory(examples)
