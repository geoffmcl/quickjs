
# CMakeLists.txt, generated gencmake.pl, on 2021/03/09 12:47:21
cmake_minimum_required( VERSION 3.6 )

# Disable in-source builds to prevent source tree corruption.
if(" ${CMAKE_SOURCE_DIR}" STREQUAL " ${CMAKE_BINARY_DIR}")
message(FATAL_ERROR "
   ***FATAL***: Building in source directory '${CMAKE_SOURCE_DIR}'!
   i.e. in-source builds are NOT recommended/allowed.
   Create and use a separate folder, like 'md build'; 'cd build; 'cmake .. [options]'
   Make sure any 'CMakeCache.txt' file, and any 'CMakeFiles' folder are deleted.")
endif()

# CMakeScripts or use the ones that come by default with CMake.
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMakeModules) # +? ${CMAKE_MODULE_PATH}

project( quickjs )

# The version number.  *** FIX ME ***
set( VERFILE VERSION )
set( quickjs_MAJOR 3 )
set( quickjs_MINOR 0 )
set( quickjs_POINT 0 )
file(READ ${VERFILE} versionFile)
if (NOT versionFile)
    message(FATAL_ERROR "Unable to determine version. ${VERFILE} file is missing.")
endif()
string(STRIP "${versionFile}" VERSION_TEXT)
add_definitions( -DCONFIG_VERSION="${VERSION_TEXT}" )

option(USE_BIG_NUMBER "Set ON to include CONFIG_BIGNUM, libbf.c" ON )
option(BUILD_SRCS "Set ON to use 'qjsc' to build 'C' sources" ON )
option(ADD_TEST262 "Set ON to build 'run-test262' EXE" OFF )

# Allow developer to select is Dynamic or static library built
set( LIB_TYPE STATIC )  # set default static
option( BUILD_SHARED_LIB "Set ON to build shared Library (DLL)" OFF )

if(CMAKE_COMPILER_IS_GNUCXX)
    set( WARNING_FLAGS -Wall )
    message(STATUS "*** Got CMAKE_COMPILER_IS_GNUCXX, added '-Wall'")
endif()

if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang") 
    set( WARNING_FLAGS "-Wall -Wno-overloaded-virtual" )
    message(STATUS "*** Compiler is 'Clang'")
endif() 

if(WIN32 AND MSVC)
    # turn off various warnings - none needed in this compile
    set(WARNING_FLAGS "${WARNING_FLAGS} /wd4996")
    # foreach(warning 4251 4275 4290 4786 4305)
    # C4244: 'function': conversion from 'int64_t' to 'int32_t', possible loss of data 
    # C4267: '+=': conversion from 'size_t' to 'int', possible loss of data
    # C4018: '<': signed/unsigned mismatch
    foreach(warning 4244 4267 4018)
        set(WARNING_FLAGS "${WARNING_FLAGS} /wd${warning}")
    endforeach(warning)
    # other flags: -DNOMINMAX  -D_SCL_SECURE_NO_WARNINGS -D__CRT_NONSTDC_NO_WARNINGS
    #set( MSVC_FLAGS "-D_USE_MATH_DEFINES -D_CRT_SECURE_NO_WARNINGS" )
    set( MSVC_FLAGS "-D_USE_MATH_DEFINES -D_CRT_SECURE_NO_WARNINGS -DJS_STRICT_NAN_BOXING -D_HAS_EXCEPTIONS=0" )
    #set( NOMINMAX 1 )
    # to distinguish between debug and release libs
    set( CMAKE_DEBUG_POSTFIX "d" )
    option( USE_STATIC_RUNTIME "Set ON to change /MD(DLL) to /MT(static)" ON )
    if (USE_STATIC_RUNTIME)
        set(CompilerFlags
            CMAKE_CXX_FLAGS
            CMAKE_CXX_FLAGS_DEBUG
            CMAKE_CXX_FLAGS_RELEASE
            CMAKE_C_FLAGS
            CMAKE_C_FLAGS_DEBUG
            CMAKE_C_FLAGS_RELEASE
            )
        foreach(CompilerFlag ${CompilerFlags})
            string(REPLACE "/MD" "/MT" ${CompilerFlag} "${${CompilerFlag}}")
        endforeach()    
        message(STATUS "Using /MT STATIC runtime")
    else ()
        message(STATUS "Using /MD DYNAMIC runtime")
    endif ()
else()
    # items for unix or mingw
    set(WARNING_FLAGS "${WARNING_FLAGS} -Wno-array-bounds -Wno-format-truncation -Wno-unused-variable -Wno-unused-but-set-variable") 
    if(CMAKE_C_COMPILER_ID)
        if(WIN32)
            if(MINGW)
                #if(MINGW_GCC_BUG)
                set(WARNING_FLAGS "${WARNING_FLAGS} -fno-reorder-blocks-and-partition") 
                #endif()
                # set(WARNING_FLAGS "${WARNING_FLAGS} -flto") # hmmm, this causes probs
                set(WARNING_FLAGS "${WARNING_FLAGS} -MMD -MF")
                message(STATUS "*** WIN32/MINGW. Compiler id '${CMAKE_C_COMPILER_ID}' ")
                #add_definitions( -D_GNU_SOURCE )
                #add_definitions( -DCONFIG_BIGNUM )
                # add_definitions( -DCONFIG_CHECK_JSVALUE )
            else()
                message(STATUS "*** WIN32, NOT MSVC/MINGW. Compiler id '${CMAKE_C_COMPILER_ID}' ")
            endif()
        else()
            message(STATUS "*** NOT WIN32/MSVC. Compiler id '${CMAKE_C_COMPILER_ID}' ")
        endif()
    else()
        message(STATUS "*** Compiler is 'unix', but NO 'CMAKE_C_COMPILER_ID'")
    endif()
    set(MSVC_LD_FLAGS "${MSVC_LD_FLAGS} -pthread")
    # Explicitly link -lm on most Unices.
    if(UNIX AND NOT APPLE AND NOT BEOS AND NOT HAIKU)
        find_library(MATH_LIBRARY m)
        if(MATH_LIBRARY)
            message( STATUS "*** Explicitly adding maths lib ${MATH_LIBRARY} and dl lib ${CMAKE_DL_LIBS}")
            list( APPEND add_LIBS ${MATH_LIBRARY} ${CMAKE_DL_LIBS})
        else ()
            message(FATAL_ERROR "*** UGH: match library NOT found")
        endif ()
    # For Windows and Mac, don't need to explicitly include the math library
    endif()
    find_package(Threads)
    if (Threads_FOUND)
        message(STATUS "*** Found Threads incs ${Threads_INCLUDE_DIR} libs ${Threads_LIBRARIES}")
        list(APPEND add_LIBS ${Threads_LIBRARIES})
    else ()
        message(FATAL_ERROR "*** Threads NOT FOUND!")
    endif ()
    list(APPEND add_LIBS "-ldbus-1")
endif()

set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${WARNING_FLAGS} ${MSVC_FLAGS} -D_REENTRANT" )
set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${WARNING_FLAGS} ${MSVC_FLAGS} -D_REENTRANT" )
set( CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${MSVC_LD_FLAGS}" )

add_definitions( -D_GNU_SOURCE )

if(MSVC)
# Once done this will define
#  DIRENT_FOUND - System has dirent
#  DIRENT_INCLUDE_DIRS - The dirent.h include directories
#  DIRENT_LIBRARIES - The static library needed to use dirent
find_package( DIRENT )
if(DIRENT_FOUND)
    message(STATUS "*** Found Dirent inc ${DIRENT_INCLUDE_DIRS}, lib ${DIRENT_LIBRARIES}")
    include_directories( ${DIRENT_INCLUDE_DIRS} )
    list(APPEND add_LIBS ${DIRENT_LIBRARIES})
else()
    message(FATAL_ERROR "*** Dirent NOT FOUND")
endif()

# Once done this will define
#  GETOPT_FOUND - System has GETOPT
#  GETOPT_INCLUDE_DIRS - The getopt.h include directories
#  GETOPT_LIBRARIES - The static library needed to use getopt
find_package( GETOPT )
if(GETOPT_FOUND)
    message(STATUS "*** Found Getopt inc ${GETOPT_INCLUDE_DIRS}, lib ${GETOPT_LIBRARIES}")
    include_directories( ${GETOPT_INCLUDE_DIRS} )
    list(APPEND add_LIBS ${GETOPT_LIBRARIES})
else()
    message(FATAL_ERROR "*** Getopt NOT FOUND")
endif()
endif(MSVC)

# configuration file, if needed
# configure_file( ${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h )
# add_definitions( -DHAVE_CONFIG_H )
# include_directories( ${CMAKE_BINARY_DIR} )

if(BUILD_SHARED_LIB)
   set(LIB_TYPE SHARED)
   message(STATUS "*** Building DLL library ${LIB_TYPE}")
else()
   message(STATUS "*** Option BUILD_SHARED_LIB is OFF ${LIB_TYPE}")
endif()

set(dir .)
set(LIB_SRCS
    ${dir}/quickjs.c
    ${dir}/libregexp.c
    ${dir}/libunicode.c
    ${dir}/cutils.c
    ${dir}/quickjs-libc.c
    )
set(LIB_HDRS
    ${dir}/quickjs.h
    ${dir}/quickjs-atom.h
    ${dir}/quickjs-libc.h
    ${dir}/quickjs-opcode.h
    ${dir}/quickjs-version.h
    )
if(USE_BIG_NUMBER)
    list(APPEND LIB_SRCS ${dir}/libbf.c)
    #list(APPEND LIB_HDRS ${dir}/libbf.h)
    add_definitions( -DCONFIG_BIGNUM )
    message(STATUS "*** Option USE_BIG_NUMBER is ON")
else()
    message(STATUS "*** Option USE_BIG_NUMBER is OFF")
endif()

# quickjs LIBRARY [D:\Projects\quickjs],
# have 10 C/C++ sources, 12 headers
# QJS_LIB_OBJS=$(OBJDIR)/quickjs.o $(OBJDIR)/libregexp.o $(OBJDIR)/libunicode.o $(OBJDIR)/cutils.o $(OBJDIR)/quickjs-libc.o
# ifdef CONFIG_BIGNUM QJS_LIB_OBJS+=$(OBJDIR)/libbf.o 

set(name quickjs)
set(dir .)
set(${name}_SRCS
    ${LIB_SRCS}
    )
set(${name}_HDRS
    ${dir}/cutils.h
    ${dir}/libregexp-opcode.h
    ${dir}/libregexp.h
    ${dir}/libunicode-table.h
    ${dir}/libunicode.h
    ${dir}/list.h
    ${LIB_HDRS}
    )
if(USE_BIG_NUMBER)
    list(APPEND ${${name}_HDRS} ${dir}/libbf.h)
endif()
add_library( ${name} ${${name}_SRCS} ${${name}_HDRS} )
if (add_LIBS OR extra_LIBS)
    target_link_libraries( ${name} ${add_LIBS} ${extra_LIBS} )
endif ()
list(APPEND add_LIBS ${name})
# deal with install, if any...
install( TARGETS ${name}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib )
install(FILES ${LIB_HDRS} DESTINATION include/quickjs)

# Total libs 2, exes 1
#################################################
##### LIBRARIES 2 #####
#################################################

if(ADD_EXTRA_LIBS)
# bjson LIBRARY from [tests],
# have 1 C/C++ sources, 0 headers
set(name bjson)
set(dir tests)
set(${name}_SRCS
    ${dir}/bjson.c
    )
add_library( ${name} ${${name}_SRCS} )
list(APPEND add_LIBS ${name})
# deal with install, if any...
#install( TARGETS ${name}
#    RUNTIME DESTINATION bin
#    LIBRARY DESTINATION lib
#    ARCHIVE DESTINATION lib )
#install(FILES ${${name}_HDRS} DESTINATION include)

# examples LIBRARY from [examples],
# have 2 C/C++ sources, 0 headers
set(name examples)
set(dir examples)
set(${name}_SRCS
    ${dir}/fib.c
    ${dir}/point.c
    )
add_library( ${name} ${${name}_SRCS} )
list(APPEND add_LIBS ${name})
# deal with install, if any...
#install( TARGETS ${name}
#    RUNTIME DESTINATION bin
#    LIBRARY DESTINATION lib
#    ARCHIVE DESTINATION lib )
#install(FILES ${${name}_HDRS} DESTINATION include)
endif(ADD_EXTRA_LIBS)

#################################################
##### EXECUTABLE #####
#################################################
set(name qjsc)
set(dir .)
set(${name}_SRCS
    ${dir}/qjsc.c
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS OR extra_LIBS)
    target_link_libraries( ${name} ${add_LIBS} ${extra_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()
install(TARGETS ${name} DESTINATION bin)

# need to build custom 'repl.c', in build dir only
set(BLT_SRC ${CMAKE_BINARY_DIR}/repl.c )
set(BLT_SRC2 ${CMAKE_BINARY_DIR}/qjscalc.c )

# if(NOT MSVC)
if(BUILD_SRCS)
#################################################
add_custom_command(OUTPUT ${BLT_SRC}
    COMMAND qjsc -c -o ${BLT_SRC} -m ${dir}/repl.js
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${CMAKE_SOURCE_DIR}/repl.js
    )

# ./qjsc -fbignum -c -o qjscalc.c qjscalc.js
set(_FLAG)
if(USE_BIG_NUMBER)
set(_FLAG -fbignum)
endif()
add_custom_command(OUTPUT ${BLT_SRC2}
    COMMAND qjsc ${_FLAG} -c -o ${BLT_SRC2} ${CMAKE_SOURCE_DIR}/qjscalc.js
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${CMAKE_SOURCE_DIR}/qjscalc.js
    )
#################################################
endif()

set(name qjs)
set(dir .)
set(${name}_SRCS
    ${dir}/qjs.c
    ${BLT_SRC}
    ${BLT_SRC2}
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS OR extra_LIBS)
    target_link_libraries( ${name} ${add_LIBS} ${extra_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()
install(TARGETS ${name} DESTINATION bin)

if(ADD_TEST262) # MSVC need to add some things
set(name run-test262)
set(dir .)
set(${name}_SRCS
    ${dir}/run-test262.c
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS OR extra_LIBS)
    target_link_libraries( ${name} ${add_LIBS} ${extra_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()
endif()

if(ADD_UNICODE_GEN)
set(name unicode_gen)
set(dir .)
set(${name}_SRCS
    ${dir}/unicode_gen.c
    ${dir}/unicode_gen_def.h
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS OR extra_LIBS)
    target_link_libraries( ${name} ${add_LIBS} ${extra_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()
endif(ADD_UNICODE_GEN)

# eof
