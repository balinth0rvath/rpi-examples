# TARGET_SDK can be:
# rpi3-poky-morty
# rpi3-raspbian-buster
# todo
# imx6-poky-rocko
# rpi0-poky-rocko


IF ("${TARGET_SDK}" STREQUAL "")
	MESSAGE("No TARGET_SDK specified. Building for rpi3-poky-morty")
	MESSAGE("-----------------------------------------------------")
	MESSAGE("Valid SDK's are:")
	MESSAGE(" rpi3-poky-morty")
	MESSAGE(" rpi3-raspbian-buster")
	MESSAGE("todo:")
	MESSAGE(" rpi0-poky-rocko")
	MESSAGE("-----------------------------------------------------")

	SET(TARGET_SDK "rpi3-poky-morty")
ENDIF()
MESSAGE("")
MESSAGE("*********************************************************")
MESSAGE("* Configuring ${TARGET_SDK}")
MESSAGE("*********************************************************")
MESSAGE("")

MESSAGE("Deleting _build/CMakeFiles folder")
EXECUTE_PROCESS(COMMAND rm -rf ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles)
SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_VERSION 1)
# Where is the target environment
cmake_minimum_required(VERSION 3.10)
project(hello VERSION 1.0)

IF ("${TARGET_SDK}" STREQUAL "rpi3-poky-morty")
	SET(CMAKE_C_FLAGS "-march=armv7ve -marm -mfpu=neon-vfpv4 -mfloat-abi=hard -mcpu=cortex-a7")
	SET(CMAKE_CXX_FLAGS "-march=armv7ve -marm -mfpu=neon-vfpv4  -mfloat-abi=hard -mcpu=cortex-a7")
	SET(CMAKE_C_FLAGS_INIT "-march=armv7ve -marm -mfpu=neon-vfpv4  -mfloat-abi=hard -mcpu=cortex-a7")
	SET(CMAKE_CXX_FLAGS_INIT "-march=armv7ve -marm -mfpu=neon-vfpv4  -mfloat-abi=hard -mcpu=cortex-a7")
	SET(CMAKE_C_COMPILER "/opt/poky/2.2.4/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/arm-poky-linux-gnueabi-gcc" )
	SET(CMAKE_CXX_COMPILER "/opt/poky/2.2.4/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/arm-poky-linux-gnueabi-g++" )
	SET(CMAKE_FIND_ROOT_PATH "/opt/poky/2.2.4/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi")

	SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --sysroot=${CMAKE_FIND_ROOT_PATH}")
	SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} --sysroot=${CMAKE_FIND_ROOT_PATH}")
	SET(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} --sysroot=${CMAKE_FIND_ROOT_PATH}")
ENDIF()

IF ("${TARGET_SDK}" STREQUAL "rpi3-raspbian-buster")
	SET(CMAKE_C_COMPILER "/opt/raspbian/buster/sysroots/x86_64-raspbiansdk-linux/bin/arm-linux-gnueabihf-gcc")
	SET(CMAKE_CXX_COMPILER "/opt/raspbian/buster/sysroots/x86_64-raspbiansdk-linux/bin/arm-linux-gnueabihf-g++")
	SET(CMAKE_FIND_ROOT_PATH "/opt/raspbian/buster/sysroots/arm-raspbian-linux-gnueabi")
ENDIF()




SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

SET(BASEPATH "${CMAKE_SOURCE_DIR}")
INCLUDE_DIRECTORIES("${BASEPATH}")
IF (${TARGET_SDK} STREQUAL "rpi3-poky-morty")
	INCLUDE_DIRECTORIES("${CMAKE_FIND_ROOT_PATH}/usr/include")
ENDIF()

add_executable(hello hello.c)
