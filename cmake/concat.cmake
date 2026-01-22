if(NOT DEFINED OUTPUT)
  message(FATAL_ERROR "OUTPUT is required")
endif()
if(NOT DEFINED INPUTS_FILE)
  message(FATAL_ERROR "INPUTS_FILE is required")
endif()

get_filename_component(out_dir "${OUTPUT}" DIRECTORY)
file(MAKE_DIRECTORY "${out_dir}")

file(READ "${INPUTS_FILE}" inputs_raw)
string(REPLACE "\n" ";" input_list "${inputs_raw}")
list(REMOVE_ITEM input_list "")

file(WRITE "${OUTPUT}" "")
foreach(input IN LISTS input_list)
  file(READ "${input}" content)
  file(APPEND "${OUTPUT}" "${content}")
endforeach()
