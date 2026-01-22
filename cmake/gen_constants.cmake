if(NOT DEFINED AWK_EXECUTABLE)
  message(FATAL_ERROR "AWK_EXECUTABLE is required")
endif()
if(NOT DEFINED AWK_SCRIPT)
  message(FATAL_ERROR "AWK_SCRIPT is required")
endif()
if(NOT DEFINED INPUT)
  message(FATAL_ERROR "INPUT is required")
endif()
if(NOT DEFINED OUTPUT)
  message(FATAL_ERROR "OUTPUT is required")
endif()

get_filename_component(out_dir "${OUTPUT}" DIRECTORY)
file(MAKE_DIRECTORY "${out_dir}")

execute_process(
  COMMAND "${AWK_EXECUTABLE}" -f "${AWK_SCRIPT}" "${INPUT}"
  OUTPUT_FILE "${OUTPUT}"
  RESULT_VARIABLE res
)
if(NOT res EQUAL 0)
  message(FATAL_ERROR "awk failed with exit code ${res}")
endif()
