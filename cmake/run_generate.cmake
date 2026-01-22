if(NOT DEFINED GENERATE_EXE)
  message(FATAL_ERROR "GENERATE_EXE is required")
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

execute_process(
  COMMAND "${GENERATE_EXE}" -g "${MODE}" "${INPUT}"
  OUTPUT_FILE "${OUTPUT}"
  RESULT_VARIABLE res
)
if(NOT res EQUAL 0)
  message(FATAL_ERROR "generate failed with exit code ${res}")
endif()
