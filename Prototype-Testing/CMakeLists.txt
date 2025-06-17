cmake_minimum_required(VERSION 3.10)
project(MyProject)

set(CMAKE_CXX_STANDARD 17)

include_directories(include)

find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})

# Create the executable with all source files
add_executable(SystolicArrayNPU
    src/SystolicArray.cpp
    src/PE.cpp
    src/LReLU.cpp)

target_link_libraries(SystolicArrayNPU ${OpenCV_LIBS})
