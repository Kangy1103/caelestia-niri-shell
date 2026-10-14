qml_module(CNS-internal
    URI CNS.Internal
    SOURCES
        cachingimagemanager.hpp cachingimagemanager.cpp
        circularbuffer.hpp circularbuffer.cpp
        niriipc.hpp niriipc.cpp
        nirisocket.hpp nirisocket.cpp
        visualiserbars.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Concurrent
        Qt::Network
        Qt::DBus
)
