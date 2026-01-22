if(NOT DEFINED TL_PARSER_EXE)
  message(FATAL_ERROR "TL_PARSER_EXE is required")
endif()
if(NOT DEFINED INPUT)
  message(FATAL_ERROR "INPUT is required")
endif()
if(NOT DEFINED OUTPUT)
  message(FATAL_ERROR "OUTPUT is required")
endif()
if(NOT DEFINED MODE)
  message(FATAL_ERROR "MODE is required")
endif()

get_filename_component(out_dir "${OUTPUT}" DIRECTORY)
file(MAKE_DIRECTORY "${out_dir}")

if(MODE STREQUAL "e")
  execute_process(
    COMMAND "${TL_PARSER_EXE}" -e "${OUTPUT}" "${INPUT}"
    RESULT_VARIABLE res
  )
elseif(MODE STREQUAL "E")
  execute_process(
    COMMAND "${TL_PARSER_EXE}" -E "${INPUT}"
    ERROR_FILE "${OUTPUT}"
    RESULT_VARIABLE res
  )
else()
  message(FATAL_ERROR "Unknown MODE: ${MODE}")
endif()

if(NOT res EQUAL 0)
  message(FATAL_ERROR "tl-parser failed with exit code ${res}")
endif()
