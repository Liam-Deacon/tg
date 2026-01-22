cmake_minimum_required(VERSION 3.16)
project(telegram-cli VERSION 1.0 LANGUAGES C)

include(GNUInstallDirs)
include(CheckIncludeFile)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

option(TG_ENABLE_LIBEVENT "Enable libevent support" ON)
option(TG_ENABLE_LUA "Enable Lua scripting support" ON)
option(TG_ENABLE_PYTHON "Enable Python scripting support" OFF)
option(TG_ENABLE_JSON "Enable JSON support" ON)
option(TG_ENABLE_LIBCONFIG "Enable libconfig support" ON)
option(TG_ENABLE_EXTF "Enable extended queries" ON)
option(TG_ENABLE_STATIC "Link statically when possible (non-macOS)" OFF)
set(TG_PROG_NAME "telegram-cli" CACHE STRING "Program name override")

find_package(PkgConfig)
find_package(OpenSSL REQUIRED)
find_package(ZLIB REQUIRED)
find_package(Threads REQUIRED)
find_program(AWK_EXECUTABLE awk gawk)
if(NOT AWK_EXECUTABLE)
  message(FATAL_ERROR "awk not found")
endif()

set(EXTRA_LIBS "")

if(NOT TG_ENABLE_LIBEVENT)
  message(FATAL_ERROR "libevent is required; TG_ENABLE_LIBEVENT=OFF is not supported")
endif()
if(PKG_CONFIG_FOUND)
  pkg_search_module(LIBEVENT libevent)
endif()
if(NOT LIBEVENT_FOUND)
  find_path(LIBEVENT_INCLUDE_DIRS event2/event.h event.h)
  find_library(LIBEVENT_LIBRARIES event)
  if(LIBEVENT_INCLUDE_DIRS AND LIBEVENT_LIBRARIES)
    set(LIBEVENT_FOUND TRUE)
  endif()
endif()
if(NOT LIBEVENT_FOUND)
  message(FATAL_ERROR "libevent not found")
endif()

if(TG_ENABLE_LIBCONFIG)
  if(PKG_CONFIG_FOUND)
    pkg_search_module(LIBCONFIG libconfig)
  endif()
  if(NOT LIBCONFIG_FOUND)
    find_path(LIBCONFIG_INCLUDE_DIRS libconfig.h)
    find_library(LIBCONFIG_LIBRARIES config)
    if(LIBCONFIG_INCLUDE_DIRS AND LIBCONFIG_LIBRARIES)
      set(LIBCONFIG_FOUND TRUE)
    endif()
  endif()
  if(NOT LIBCONFIG_FOUND)
    message(FATAL_ERROR "libconfig not found (disable with -DTG_ENABLE_LIBCONFIG=OFF)")
  endif()
endif()

if(TG_ENABLE_JSON)
  if(PKG_CONFIG_FOUND)
    pkg_search_module(JANSSON jansson)
  endif()
  if(NOT JANSSON_FOUND)
    find_path(JANSSON_INCLUDE_DIRS jansson.h)
    find_library(JANSSON_LIBRARIES jansson)
    if(JANSSON_INCLUDE_DIRS AND JANSSON_LIBRARIES)
      set(JANSSON_FOUND TRUE)
    endif()
  endif()
  if(NOT JANSSON_FOUND)
    message(FATAL_ERROR "jansson not found (disable with -DTG_ENABLE_JSON=OFF)")
  endif()
endif()

if(TG_ENABLE_LUA)
  if(PKG_CONFIG_FOUND)
    pkg_search_module(LUA lua5.4 lua5.3 lua5.2 lua5.1 lua)
  endif()
  if(NOT LUA_FOUND)
    find_path(LUA_INCLUDE_DIRS lua.h)
    find_library(LUA_LIBRARIES lua5.4 lua5.3 lua5.2 lua5.1 lua)
    if(LUA_INCLUDE_DIRS AND LUA_LIBRARIES)
      set(LUA_FOUND TRUE)
    endif()
  endif()
  if(NOT LUA_FOUND)
    message(FATAL_ERROR "lua not found (disable with -DTG_ENABLE_LUA=OFF)")
  endif()
endif()

if(PKG_CONFIG_FOUND)
  pkg_search_module(READLINE readline)
endif()
if(NOT READLINE_FOUND)
  find_path(READLINE_INCLUDE_DIRS readline/readline.h)
  find_library(READLINE_LIBRARIES readline)
  if(READLINE_INCLUDE_DIRS AND READLINE_LIBRARIES)
    set(READLINE_FOUND TRUE)
  endif()
endif()
if(NOT READLINE_FOUND)
  message(FATAL_ERROR "readline not found")
endif()

if(TG_ENABLE_PYTHON)
  find_package(Python3 COMPONENTS Development REQUIRED)
endif()

find_library(DL_LIBRARY dl)
if(DL_LIBRARY)
  list(APPEND EXTRA_LIBS ${DL_LIBRARY})
endif()

find_library(UTIL_LIBRARY util)
if(UTIL_LIBRARY)
  list(APPEND EXTRA_LIBS ${UTIL_LIBRARY})
endif()

find_library(EXECINFO_LIBRARY execinfo)
if(EXECINFO_LIBRARY)
  list(APPEND EXTRA_LIBS ${EXECINFO_LIBRARY})
endif()

set(CMAKE_REQUIRED_INCLUDES "")
if(LIBEVENT_INCLUDE_DIRS)
  set(CMAKE_REQUIRED_INCLUDES ${LIBEVENT_INCLUDE_DIRS})
endif()
check_include_file("event2/event.h" HAVE_EVENT2_H)
check_include_file("event.h" HAVE_EVENT_H)
set(CMAKE_REQUIRED_INCLUDES "")

set(EVENT_V2)
set(EVENT_V1)
if(HAVE_EVENT2_H)
  set(EVENT_V2 1)
elseif(HAVE_EVENT_H)
  set(EVENT_V1 1)
else()
  message(FATAL_ERROR "libevent headers not found")
endif()

check_include_file("execinfo.h" HAVE_EXECINFO_H)

set(USE_LUA)
set(USE_PYTHON)
set(USE_JSON)
set(HAVE_LIBCONFIG)
set(DISABLE_EXTF)

if(TG_ENABLE_LUA)
  set(USE_LUA 1)
endif()
if(TG_ENABLE_PYTHON)
  set(USE_PYTHON 1)
endif()
if(TG_ENABLE_JSON)
  set(USE_JSON 1)
endif()
if(TG_ENABLE_LIBCONFIG)
  set(HAVE_LIBCONFIG 1)
endif()
if(NOT TG_ENABLE_EXTF)
  set(DISABLE_EXTF 1)
endif()

configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/config.h.in
  ${CMAKE_CURRENT_BINARY_DIR}/config.h
  @ONLY
)
configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/config.h.in
  ${CMAKE_CURRENT_SOURCE_DIR}/tgl/config.h
  @ONLY
)

set(TGL_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/tgl)
set(TGL_BIN_DIR ${CMAKE_CURRENT_BINARY_DIR}/tgl)
set(TGL_AUTO_DIR ${TGL_BIN_DIR}/auto)

set(TGL_SCHEME_SOURCES
  ${TGL_SRC_DIR}/scheme.tl
  ${TGL_SRC_DIR}/encrypted_scheme.tl
  ${TGL_SRC_DIR}/binlog.tl
  ${TGL_SRC_DIR}/append.tl
  ${TGL_SRC_DIR}/mtproto.tl
)
string(JOIN "|" TGL_SCHEME_SOURCES_PIPE ${TGL_SCHEME_SOURCES})

add_executable(tg_tl_parser
  ${TGL_SRC_DIR}/tl-parser/tl-parser.c
  ${TGL_SRC_DIR}/tl-parser/tlc.c
)
target_include_directories(tg_tl_parser PRIVATE
  ${CMAKE_CURRENT_BINARY_DIR}
  ${TGL_SRC_DIR}/tl-parser
)
target_compile_definitions(tg_tl_parser PRIVATE HAVE_CONFIG_H)
target_link_libraries(tg_tl_parser PRIVATE ZLIB::ZLIB ${EXTRA_LIBS})

add_executable(tg_generate
  ${TGL_SRC_DIR}/generate.c
  ${TGL_SRC_DIR}/tools.c
  ${TGL_SRC_DIR}/crypto/err_openssl.c
  ${TGL_SRC_DIR}/crypto/rand_openssl.c
)
target_include_directories(tg_generate PRIVATE
  ${CMAKE_CURRENT_BINARY_DIR}
  ${TGL_SRC_DIR}
)
target_compile_definitions(tg_generate PRIVATE HAVE_CONFIG_H)
target_link_libraries(tg_generate PRIVATE OpenSSL::SSL OpenSSL::Crypto ZLIB::ZLIB ${EXTRA_LIBS})

add_custom_command(
  OUTPUT ${TGL_AUTO_DIR}/scheme.tl
  COMMAND ${CMAKE_COMMAND} -E make_directory ${TGL_AUTO_DIR}
  COMMAND ${CMAKE_COMMAND} -DOUTPUT=${TGL_AUTO_DIR}/scheme.tl -DINPUTS=${TGL_SCHEME_SOURCES_PIPE}
          -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/concat.cmake
  DEPENDS ${TGL_SCHEME_SOURCES}
)

add_custom_command(
  OUTPUT ${TGL_AUTO_DIR}/scheme.tlo
  COMMAND ${CMAKE_COMMAND} -DINPUT=${TGL_AUTO_DIR}/scheme.tl -DOUTPUT=${TGL_AUTO_DIR}/scheme.tlo
          -DTL_PARSER_EXE=$<TARGET_FILE:tg_tl_parser> -DMODE=e
          -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/run_tl_parser.cmake
  DEPENDS tg_tl_parser ${TGL_AUTO_DIR}/scheme.tl
)

add_custom_command(
  OUTPUT ${TGL_AUTO_DIR}/scheme2.tl
  COMMAND ${CMAKE_COMMAND} -DINPUT=${TGL_AUTO_DIR}/scheme.tl -DOUTPUT=${TGL_AUTO_DIR}/scheme2.tl
          -DTL_PARSER_EXE=$<TARGET_FILE:tg_tl_parser> -DMODE=E
          -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/run_tl_parser.cmake
  DEPENDS tg_tl_parser ${TGL_AUTO_DIR}/scheme.tl
)

add_custom_command(
  OUTPUT ${TGL_AUTO_DIR}/constants.h
  COMMAND ${CMAKE_COMMAND} -DINPUT=${TGL_AUTO_DIR}/scheme2.tl -DOUTPUT=${TGL_AUTO_DIR}/constants.h
          -DAWK_EXECUTABLE=${AWK_EXECUTABLE} -DAWK_SCRIPT=${TGL_SRC_DIR}/gen_constants_h.awk
          -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/gen_constants.cmake
  DEPENDS ${TGL_AUTO_DIR}/scheme2.tl ${TGL_SRC_DIR}/gen_constants_h.awk
)

set(TGL_AUTO_NAMES
  skip
  fetch
  store
  autocomplete
  types
  fetch-ds
  free-ds
  store-ds
  print-ds
)

set(TGL_AUTO_HEADERS "")
set(TGL_AUTO_SOURCES "")
foreach(name IN LISTS TGL_AUTO_NAMES)
  set(auto_h ${TGL_AUTO_DIR}/auto-${name}.h)
  set(auto_c ${TGL_AUTO_DIR}/auto-${name}.c)

  add_custom_command(
    OUTPUT ${auto_h}
    COMMAND ${CMAKE_COMMAND} -DINPUT=${TGL_AUTO_DIR}/scheme.tlo -DOUTPUT=${auto_h}
            -DGENERATE_EXE=$<TARGET_FILE:tg_generate> -DMODE=${name}-header
            -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/run_generate.cmake
    DEPENDS tg_generate ${TGL_AUTO_DIR}/scheme.tlo
  )

  add_custom_command(
    OUTPUT ${auto_c}
    COMMAND ${CMAKE_COMMAND} -DINPUT=${TGL_AUTO_DIR}/scheme.tlo -DOUTPUT=${auto_c}
            -DGENERATE_EXE=$<TARGET_FILE:tg_generate> -DMODE=${name}
            -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/run_generate.cmake
    DEPENDS tg_generate ${TGL_AUTO_DIR}/scheme.tlo ${auto_h} ${TGL_AUTO_DIR}/constants.h
  )

  list(APPEND TGL_AUTO_HEADERS ${auto_h})
  list(APPEND TGL_AUTO_SOURCES ${auto_c})
endforeach()

add_library(tg STATIC
  ${TGL_SRC_DIR}/mtproto-common.c
  ${TGL_SRC_DIR}/mtproto-client.c
  ${TGL_SRC_DIR}/mtproto-key.c
  ${TGL_SRC_DIR}/queries.c
  ${TGL_SRC_DIR}/structures.c
  ${TGL_SRC_DIR}/binlog.c
  ${TGL_SRC_DIR}/tgl.c
  ${TGL_SRC_DIR}/updates.c
  ${TGL_SRC_DIR}/tg-mime-types.c
  ${TGL_SRC_DIR}/mtproto-utils.c
  ${TGL_SRC_DIR}/crypto/bn_openssl.c
  ${TGL_SRC_DIR}/crypto/bn_altern.c
  ${TGL_SRC_DIR}/crypto/rsa_pem_openssl.c
  ${TGL_SRC_DIR}/crypto/rsa_pem_altern.c
  ${TGL_SRC_DIR}/crypto/md5_openssl.c
  ${TGL_SRC_DIR}/crypto/md5_altern.c
  ${TGL_SRC_DIR}/crypto/sha_openssl.c
  ${TGL_SRC_DIR}/crypto/sha_altern.c
  ${TGL_SRC_DIR}/crypto/aes_openssl.c
  ${TGL_SRC_DIR}/crypto/aes_altern.c
  ${TGL_SRC_DIR}/crypto/err_openssl.c
  ${TGL_SRC_DIR}/crypto/err_altern.c
  ${TGL_SRC_DIR}/crypto/rand_openssl.c
  ${TGL_SRC_DIR}/crypto/rand_altern.c
  ${TGL_SRC_DIR}/tools.c
  ${TGL_AUTO_SOURCES}
)

target_sources(tg PRIVATE ${TGL_SRC_DIR}/tgl-net.c ${TGL_SRC_DIR}/tgl-timers.c)

target_include_directories(tg PRIVATE
  ${CMAKE_CURRENT_BINARY_DIR}
  ${TGL_SRC_DIR}
  ${TGL_BIN_DIR}
  ${TGL_AUTO_DIR}
  ${LIBEVENT_INCLUDE_DIRS}
)
target_compile_definitions(tg PRIVATE HAVE_CONFIG_H)
target_link_libraries(tg PRIVATE OpenSSL::SSL OpenSSL::Crypto ZLIB::ZLIB ${LIBEVENT_LIBRARIES} ${EXTRA_LIBS})

add_executable(telegram-cli
  main.c
  loop.c
  interface.c
  lua-tg.c
  json-tg.c
  python-tg.c
  python-types.c
)

target_include_directories(telegram-cli PRIVATE
  ${CMAKE_CURRENT_BINARY_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${TGL_SRC_DIR}
  ${TGL_BIN_DIR}
  ${TGL_AUTO_DIR}
  ${LIBEVENT_INCLUDE_DIRS}
  ${READLINE_INCLUDE_DIRS}
  ${LIBCONFIG_INCLUDE_DIRS}
  ${JANSSON_INCLUDE_DIRS}
  ${LUA_INCLUDE_DIRS}
  ${Python3_INCLUDE_DIRS}
)
target_compile_definitions(telegram-cli PRIVATE HAVE_CONFIG_H)
target_link_libraries(telegram-cli PRIVATE
  tg
  ${READLINE_LIBRARIES}
  ${LIBCONFIG_LIBRARIES}
  ${JANSSON_LIBRARIES}
  ${LUA_LIBRARIES}
  ${Python3_LIBRARIES}
  ${LIBEVENT_LIBRARIES}
  OpenSSL::SSL
  OpenSSL::Crypto
  ZLIB::ZLIB
  Threads::Threads
  ${EXTRA_LIBS}
)

if(TG_ENABLE_STATIC AND NOT APPLE)
  target_link_options(telegram-cli PRIVATE -static)
endif()

install(TARGETS telegram-cli RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

set(CPACK_PACKAGE_NAME "telegram-cli")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_CONTACT "Liam-Deacon")
set(CPACK_GENERATOR "TGZ")
include(CPack)
