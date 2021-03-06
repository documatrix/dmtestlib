set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/dmtestlib")
set (GETTEXT_PACKAGE "dmtestlib")
set (CMAKE_C_FLAGS "-g -O3")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
find_package (Vala REQUIRED)
include( UseVala )

set (VALA_PACKAGES ${VALA_PACKAGES} gio-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} glib-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gobject-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} posix)

set (DMTESTLIB_SOURCES ${DMTESTLIB_SOURCES} dmtestlib.vala)
set (TRV_SOURCES ${TRV_SOURCES} trv.vala)

vala_precompile(DMTESTLIB_VALA_C
  ${DMTESTLIB_SOURCES}
PACKAGES
  ${VALA_PACKAGES}
GENERATE_VAPI
  ${DMTESTLIB_NAME}
CUSTOM_VAPIS
  ${CUSTOM_VAPIS_LIST}
GENERATE_HEADER
  dmtestlib
OPTIONS
  --thread -g ${CMAKE_VALA_OPTS} ${VAPIDIRS_ARGS}
)

if(NOT ${CMAKE_SYSTEM_NAME} STREQUAL Emscripten)
  vala_precompile(TRV_VALA_C
    ${TRV_SOURCES}
  PACKAGES
    ${VALA_PACKAGES}
    libxml-2.0
  OPTIONS
    --thread -g
  )
endif()

add_library(
  ${DMTESTLIB_NAME} SHARED
  ${DMTESTLIB_VALA_C}
)

if(NOT ${CMAKE_SYSTEM_NAME} STREQUAL Emscripten)
  add_executable(
    trv
    ${TRV_VALA_C}
  )
endif()

# CREATE PKGCONFIG FILES
if(NOT DEFINED CMAKE_INSTALL_BINDIR)
  set(CMAKE_INSTALL_BINDIR bin)
endif(NOT DEFINED CMAKE_INSTALL_BINDIR)
if(NOT DEFINED CMAKE_INSTALL_LIBDIR)
  set(CMAKE_INSTALL_LIBDIR lib)
endif(NOT DEFINED CMAKE_INSTALL_LIBDIR)
set(prefix       ${CMAKE_INSTALL_PREFIX})
set(exec_prefix ${CMAKE_INSTALL_PREFIX})
if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
  set(libdir       ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR})
else()
  set(libdir       ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
endif()
set(includedir  ${CMAKE_INSTALL_PREFIX}/include)
set(LIBS         "")
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/libdmtestlib.pc.in
  ${CMAKE_CURRENT_BINARY_DIR}/${DMTESTLIB_NAME}.pc @ONLY)

# Install test result viewer
if(NOT ${CMAKE_SYSTEM_NAME} STREQUAL Emscripten)
  install(
  TARGETS
    trv
  RUNTIME DESTINATION
    bin
  )
endif()
if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
  # Install dll object
  install(
    TARGETS
      ${DMTESTLIB_NAME}
    DESTINATION
      bin/
    )
elseif(${CMAKE_SYSTEM_NAME} STREQUAL Emscripten)
  # Install shared object
  install(
    TARGETS
      ${DMTESTLIB_NAME}
    LIBRARY DESTINATION
      lib/
    ARCHIVE DESTINATION
      lib/
  )
else()
  # Install shared object
  install(
    TARGETS
      ${DMTESTLIB_NAME}
    LIBRARY DESTINATION
    lib/
  )
endif( )

# Install header files
install(
FILES
  ${CMAKE_CURRENT_BINARY_DIR}/dmtestlib.h
DESTINATION
  include/${DMTESTLIB_NAME}/
)

# Install vapi files
install(
FILES
  ${CMAKE_CURRENT_BINARY_DIR}/${DMTESTLIB_NAME}.vapi
DESTINATION
  ${CMAKE_INSTALL_PREFIX}/share/vala/vapi/
)

# Install pkg-config file...
install( FILES
  ${CMAKE_CURRENT_BINARY_DIR}/${DMTESTLIB_NAME}.pc
DESTINATION
  ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)

if(HAVE_VALADOC)
  valadoc(dmtestlib
    ${CMAKE_BINARY_DIR}/valadoc/dmtestlib
    ${APP_SOURCES}
  PACKAGES
    ${VALA_PACKAGES}
  CUSTOM_VAPIS
    ${CUSTOM_VAPIS_LIST}
  )
  install(DIRECTORY
    ${CMAKE_BINARY_DIR}/valadoc
  DESTINATION
    share/doc/dmtestlib
  )
endif()
