cmake_minimum_required(VERSION 3.16)
project(caelestia VERSION 1.2)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)

if(NOT INSTALL_QMLDIR)
    set(INSTALL_QMLDIR "/usr/lib/qt6/qml" CACHE STRING "QML module install directory")
endif()

if(NOT INSTALL_PYTHONDIR)
    execute_process(COMMAND python3 -c "import sysconfig; print(sysconfig.get_path('purelib'))"
        OUTPUT_VARIABLE _python_install_dir
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(_python_install_dir)
        set(INSTALL_PYTHONDIR "${_python_install_dir}" CACHE STRING "Python package install directory")
    else()
        set(INSTALL_PYTHONDIR "/usr/lib/python3.14/site-packages"
            CACHE STRING "Python package install directory")
    endif()
endif()

if(NOT DEFINED GIT_REVISION)
    set(GIT_REVISION "" CACHE STRING "Git revision")
endif()
if(NOT DEFINED DISTRIBUTOR)
    set(DISTRIBUTOR "" CACHE STRING "Distribution vendor")
endif()

add_subdirectory(plugin)
add_subdirectory(extras)
