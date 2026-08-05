# Install script for directory: /tmp/claude-1000/-home-ubuntu-projects-bonsai/e18851ed-a295-4eab-95de-a4359bf1bf83/scratchpad/fllama/src/llama.cpp

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/usr/local")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "1")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set default install directory permissions.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/usr/bin/objdump")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/tmp/claude-1000/-home-ubuntu-projects-bonsai/e18851ed-a295-4eab-95de-a4359bf1bf83/scratchpad/fllama/build-fl/llama.cpp/ggml/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/tmp/claude-1000/-home-ubuntu-projects-bonsai/e18851ed-a295-4eab-95de-a4359bf1bf83/scratchpad/fllama/build-fl/llama.cpp/src/cmake_install.cmake")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/tmp/claude-1000/-home-ubuntu-projects-bonsai/e18851ed-a295-4eab-95de-a4359bf1bf83/scratchpad/fllama/build-fl/llama.cpp/src/libllama.a")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include" TYPE FILE FILES
    "/tmp/claude-1000/-home-ubuntu-projects-bonsai/e18851ed-a295-4eab-95de-a4359bf1bf83/scratchpad/fllama/src/llama.cpp/include/llama.h"
    "/tmp/claude-1000/-home-ubuntu-projects-bonsai/e18851ed-a295-4eab-95de-a4359bf1bf83/scratchpad/fllama/src/llama.cpp/include/llama-cpp.h"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/llama" TYPE FILE FILES
    "/tmp/claude-1000/-home-ubuntu-projects-bonsai/e18851ed-a295-4eab-95de-a4359bf1bf83/scratchpad/fllama/build-fl/llama.cpp/llama-config.cmake"
    "/tmp/claude-1000/-home-ubuntu-projects-bonsai/e18851ed-a295-4eab-95de-a4359bf1bf83/scratchpad/fllama/build-fl/llama.cpp/llama-version.cmake"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig" TYPE FILE FILES "/tmp/claude-1000/-home-ubuntu-projects-bonsai/e18851ed-a295-4eab-95de-a4359bf1bf83/scratchpad/fllama/build-fl/llama.cpp/llama.pc")
endif()

