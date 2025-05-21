cmake_minimum_required(VERSION 3.0)
project(hello)
add_library(${CMAKE_PROJECT_NAME} SHARED "hello.c" "hello.h")

install(TARGETS ${CMAKE_PROJECT_NAME} DESTINATION lib)
install(FILES hello.h DESTINATION include)