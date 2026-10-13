qml_module(CNS-models
    URI CNS.Models
    SOURCES
        filesystemmodel.cpp
        appdb.cpp
    LIBRARIES
        Qt::Gui
        Qt::Concurrent
        Qt::Sql
)
