# The shared GLTools 4th-edition library, built once (math3d, gltools and the GLee extension loader).
add_library(gltools STATIC
  src/shared/math3d.cpp
  src/shared/gltools.cpp
  src/shared/GLee.c)
target_include_directories(gltools PUBLIC src/shared)
target_compile_definitions(gltools PUBLIC GL_GLEXT_PROTOTYPES)
target_link_libraries(gltools PUBLIC OpenGL::GL OpenGL::GLU sb4_glut)
if(UNIX)
  target_link_libraries(gltools PUBLIC m)
endif()

# Dear ImGui 1.76 (vendored in contrib/imgui) with its GLUT platform backend and the OpenGL2 and OpenGL3 renderers.
add_library(imgui STATIC
  ../contrib/imgui/imgui.cpp
  ../contrib/imgui/imgui_demo.cpp
  ../contrib/imgui/imgui_draw.cpp
  ../contrib/imgui/imgui_widgets.cpp
  ../contrib/imgui/imgui_impl_glut.cpp
  ../contrib/imgui/imgui_impl_opengl2.cpp
  ../contrib/imgui/imgui_impl_opengl3.cpp)
target_include_directories(imgui PUBLIC ../contrib/imgui)
# The OpenGL3 backend includes GLee.h itself; CUSTOM tells its header that a loader is already in place.
target_compile_definitions(imgui PUBLIC IMGUI_IMPL_OPENGL_LOADER_CUSTOM)
target_link_libraries(imgui PUBLIC gltools)

# add_demo(<chapter> <demo> SOURCES <files in the demo directory> [SHARED <files in src/shared>] [LIBS <libraries>] [IMGUI] [OPENEXR])
# Builds bin/<demo>/<demo>; the demos open their data files by relative name, so every
# non-source file in the demo directory is copied next to the binary.
function(add_demo chapter demo)
  cmake_parse_arguments(ARG "IMGUI;OPENEXR" "" "SOURCES;SHARED;LIBS" ${ARGN})
  set(dir "${CMAKE_CURRENT_SOURCE_DIR}/src/${chapter}/${demo}")
  list(TRANSFORM ARG_SOURCES PREPEND "${dir}/")
  list(TRANSFORM ARG_SHARED PREPEND "${CMAKE_CURRENT_SOURCE_DIR}/src/shared/")
  set(target ${chapter}_${demo})  # demo names repeat across chapters
  add_executable(${target} ${ARG_SOURCES} ${ARG_SHARED})
  target_link_libraries(${target} PRIVATE gltools ${ARG_LIBS})
  if(ARG_OPENEXR)
    target_link_libraries(${target} PRIVATE OpenEXR::OpenEXR)
  endif()
  if(ARG_IMGUI)
    target_link_libraries(${target} PRIVATE imgui)
  endif()
  set_target_properties(${target} PROPERTIES OUTPUT_NAME ${demo}
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/${chapter}/${demo}")
  file(GLOB data_files CONFIGURE_DEPENDS "${dir}/*")
  list(FILTER data_files EXCLUDE REGEX "\\.(c|cpp|h|hpp)$")
  foreach(file IN LISTS data_files)
    get_filename_component(name "${file}" NAME)
    if(IS_DIRECTORY "${file}")  # shader directories are opened relative to the binary
      add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${file}" "$<TARGET_FILE_DIR:${target}>/${name}")
    else()
      add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${file}" "$<TARGET_FILE_DIR:${target}>")
    endif()
  endforeach()
endfunction()

# chapt18/texfloat reads OpenEXR images; it is built only when OpenEXR is installed.
find_package(OpenEXR CONFIG QUIET)

file(GLOB chapter_files "${CMAKE_CURRENT_SOURCE_DIR}/cmake/chapt*.cmake")
list(SORT chapter_files)
foreach(chapter_file IN LISTS chapter_files)
  include("${chapter_file}")
endforeach()
