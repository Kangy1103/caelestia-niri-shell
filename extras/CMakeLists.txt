include(GNUInstallDirs)

# Version
add_executable(version version.cpp)
target_compile_definitions(version PRIVATE
    PROJECT_NAME="${PROJECT_NAME}"
    VERSION="${VERSION}"
    GIT_REVISION="${GIT_REVISION}"
    DISTRIBUTOR="${DISTRIBUTOR}"
)
install(TARGETS version DESTINATION ${CMAKE_INSTALL_LIBDIR})

# CNS CLI — Python package and entry point
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../cli/
    DESTINATION ${INSTALL_PYTHONDIR}/cns
    PATTERN "__pycache__" EXCLUDE
    PATTERN "*.pyc" EXCLUDE
)
install(PROGRAMS cns DESTINATION ${CMAKE_INSTALL_BINDIR})
