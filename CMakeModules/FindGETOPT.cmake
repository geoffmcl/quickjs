# 20210126: Replace all 'dirent' with GETOPT
# 20200501: Try to find Getopt header and library
#
# Once done this will define
#  GETOPT_FOUND - System has GETOPT
#  GETOPT_INCLUDE_DIRS - The getopt.h include directories
#  GETOPT_LIBRARIES - The static library needed to use getopt
# 
message(STATUS "*** Looking for GETOPT...")
find_path(GETOPT_INCLUDE_DIR getopt.h
          HINTS ENV GETOPT_ROOT_DIR
          PATH_SUFFIXES include 
          )

if (MSVC)
########################################################################
find_library(GETOPT_LIBRARY_DEBUG NAMES getoptd
             HINTS ENV GETOPT_ROOT_DIR
             PATH_SUFFIXES lib 
             )
find_library(GETOPT_LIBRARY_RELEASE NAMES getopt
             HINTS ENV GETOPT_ROOT_DIR
             PATH_SUFFIXES lib 
             )
if (GETOPT_LIBRARY_DEBUG AND GETOPT_LIBRARY_RELEASE)
    set(GETOPT_LIBRARIES 
        debug ${GETOPT_LIBRARY_DEBUG}
        optimized ${GETOPT_LIBRARY_RELEASE} )
elseif (GETOPT_LIBRARY_RELEASE)
    set(GETOPT_LIBRARIES ${GETOPT_LIBRARY_RELEASE} )
endif ()
########################################################################
else ()
########################################################################
find_library(GETOPT_LIBRARY NAMES getopt libgetopt
             HINTS ENV GETOPT_ROOT_DIR
             PATH_SUFFIXES lib 
             )
set(GETOPT_LIBRARIES ${GETOPT_LIBRARY} )
########################################################################
endif ()
set(GETOPT_INCLUDE_DIRS ${GETOPT_INCLUDE_DIR} )

include(FindPackageHandleStandardArgs)
# handle the QUIETLY and REQUIRED arguments and set GETOP_FOUND to TRUE
# if all listed variables are TRUE
find_package_handle_standard_args(GETOPT  DEFAULT_MSG
                                  GETOPT_LIBRARIES GETOPT_INCLUDE_DIRS)

mark_as_advanced(GETOPT_INCLUDE_DIRS GETOPT_LIBRARIES)

# eof
