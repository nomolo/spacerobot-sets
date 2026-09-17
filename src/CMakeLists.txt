cmake_minimum_required(VERSION 3.18)
project(bindings LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Use modern Python discovery, while accepting the README's legacy option.
if(DEFINED PYTHON_EXECUTABLE AND NOT DEFINED Python_EXECUTABLE)
    set(Python_EXECUTABLE "${PYTHON_EXECUTABLE}")
endif()
find_package(Python REQUIRED COMPONENTS Interpreter Development.Module)
set(PYBIND11_FINDPYTHON ON)

set(THIRDPARTY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../3rdparty")

# Only build the dependencies needed by the Python module.
set(EIGEN_BUILD_TESTING OFF)
set(EIGEN_BUILD_DOC OFF)
set(EIGEN_BUILD_BLAS OFF)
set(EIGEN_BUILD_LAPACK OFF)
set(EIGEN_BUILD_DEMOS OFF)
add_subdirectory("${THIRDPARTY_DIR}/eigen-3.4.1"
                 "${CMAKE_CURRENT_BINARY_DIR}/3rdparty/eigen" EXCLUDE_FROM_ALL)

set(YAML_CPP_BUILD_TESTS OFF)
set(YAML_CPP_BUILD_TOOLS OFF)
set(YAML_CPP_INSTALL OFF)
set(YAML_BUILD_SHARED_LIBS OFF)
# Static yaml-cpp must be position-independent to link into a Python module.
set(YAML_ENABLE_PIC ON)
add_subdirectory("${THIRDPARTY_DIR}/yaml-cpp-yaml-cpp-0.9.0"
                 "${CMAKE_CURRENT_BINARY_DIR}/3rdparty/yaml-cpp" EXCLUDE_FROM_ALL)

set(PYBIND11_TEST OFF)
set(PYBIND11_INSTALL OFF)
add_subdirectory("${THIRDPARTY_DIR}/pybind11-3.1.0"
                 "${CMAKE_CURRENT_BINARY_DIR}/3rdparty/pybind11" EXCLUDE_FROM_ALL)

pybind11_add_module(bindings bindings.cpp)
target_link_libraries(bindings PRIVATE Eigen3::Eigen yaml-cpp::yaml-cpp)
