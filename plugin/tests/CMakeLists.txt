cmake_minimum_required(VERSION 3.19)
project(CNSIpcTests LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 REQUIRED COMPONENTS Core Network Qml Test Quick Multimedia Concurrent Sql)
enable_testing()

add_executable(umbrielipc_lifecycle
    umbrielipc_lifecycle.cpp
    ../src/Caelestia/Internal/umbrielipc.cpp
    ../src/Caelestia/Internal/umbrielipc.hpp
)
target_link_libraries(umbrielipc_lifecycle PRIVATE Qt6::Core Qt6::Network Qt6::Qml Qt6::Test)

option(CNS_TEST_SANITIZERS "Enable address and undefined-behaviour sanitizers" OFF)
if(CNS_TEST_SANITIZERS)
    target_compile_options(umbrielipc_lifecycle PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
    target_link_options(umbrielipc_lifecycle PRIVATE -fsanitize=address,undefined)
endif()

add_test(NAME umbrielipc_lifecycle COMMAND umbrielipc_lifecycle)
if(CNS_TEST_SANITIZERS)
    set_tests_properties(umbrielipc_lifecycle PROPERTIES ENVIRONMENT "UBSAN_OPTIONS=halt_on_error=1")
endif()

add_subdirectory(../3rdparty/rgbcx rgbcx)
set(multimedia ../src/Caelestia/Multimedia)
add_executable(multimedia_lifecycle
    multimedia_lifecycle.cpp
    ${multimedia}/visualsource.cpp ${multimedia}/visualsource.hpp
    ${multimedia}/imagecache.cpp ${multimedia}/imagecacheworker.cpp
    ${multimedia}/imagecacheworker.hpp ${multimedia}/ktxencoder.cpp
)
target_link_libraries(multimedia_lifecycle PRIVATE
    Qt6::Quick Qt6::Multimedia Qt6::Concurrent Qt6::Sql Qt6::Test rgbcx)
if(CNS_TEST_SANITIZERS)
    target_compile_options(multimedia_lifecycle PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
    target_link_options(multimedia_lifecycle PRIVATE -fsanitize=address,undefined)
endif()
add_test(NAME multimedia_lifecycle COMMAND multimedia_lifecycle)
set_tests_properties(multimedia_lifecycle PROPERTIES
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen;UBSAN_OPTIONS=halt_on_error=1")
