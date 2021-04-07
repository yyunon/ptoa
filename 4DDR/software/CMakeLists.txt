cmake_minimum_required(VERSION 3.14 FATAL_ERROR)

project(example VERSION 0.0.0 LANGUAGES C CXX)

find_library(FLETCHER fletcher)
if(NOT FLETCHER)
  message(FATAL_ERROR "Fletcher runtime library was not found")
endif()
add_library(fletcher SHARED IMPORTED GLOBAL)
set_target_properties(fletcher PROPERTIES IMPORTED_LOCATION ${FLETCHER})

include(FetchContent)

FetchContent_Declare(cmake-modules
  GIT_REPOSITORY  https://github.com/abs-tudelft/cmake-modules.git
  GIT_TAG         master
)
FetchContent_MakeAvailable(cmake-modules)

include(CompileUnits)

add_compile_unit(
  NAME
    example_lib
  TYPE
    SHARED
  PRPS
    CXX_STANDARD 11
  SRCS
    src/lib.cpp
    src/test_main.cpp
  DEPS
    fletcher
)

add_compile_unit(
  NAME
    example
  TYPE
    EXECUTABLE
  PRPS
    CXX_STANDARD 11
  SRCS
    src/main.cpp
  DEPS
    example_lib
)

compile_units()
