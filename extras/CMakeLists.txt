include(GNUInstallDirs)

if(NOT INSTALL_PYTHONDIR)
    execute_process(COMMAND python3 -c "import sysconfig; print(sysconfig.get_path('purelib'))"
        OUTPUT_VARIABLE _python_install_dir
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(_python_install_dir)
        set(INSTALL_PYTHONDIR "${_python_install_dir}" CACHE STRING "Python package install directory")
    else()
        set(INSTALL_PYTHONDIR "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/python3.14/site-packages"
            CACHE STRING "Python package install directory")
    endif()
endif()

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
