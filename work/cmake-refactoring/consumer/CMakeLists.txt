cmake_minimum_required(VERSION 4.5.0)
project(MyImportStdConsumer LANGUAGES CXX)

find_package(MyImportStd 0.1 CONFIG REQUIRED)
add_executable(consumer ../../../examples/module_consumer.cpp)
target_link_libraries(consumer PRIVATE MyImportStd::modules)
set_target_properties(consumer PROPERTIES CXX_EXTENSIONS OFF)
enable_testing()
add_test(NAME installed_module_consumer COMMAND consumer)
