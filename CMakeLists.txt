cmake_minimum_required(VERSION 3.20)
project(OpenGLSuperBible4 LANGUAGES C CXX)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

# The demos are OpenGL 2.1 compatibility code and call ARB entry points that only libGL exports, not GLVND's
# libOpenGL; prefer libGL, as the old Makefiles' -lGL did.
set(OpenGL_GL_PREFERENCE LEGACY)
find_package(OpenGL REQUIRED)
find_package(GLUT REQUIRED)

add_subdirectory(examples)
