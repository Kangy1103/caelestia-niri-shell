qml_module(CNS-multimedia
    URI CNS.Multimedia
    SOURCES
        visualsource.cpp
        imagecache.cpp
        imagecacheworker.cpp
        ktxencoder.cpp
    QML_FILES
        Visual.qml
    LIBRARIES
        Qt::Quick
        Qt::Multimedia
        Qt::Concurrent
        Qt::Sql
        rgbcx
)

qt_add_shaders(CNS-multimedia cns-wallpaper-shaders
    PREFIX "/CNS/Multimedia/shaders"
    BASE shaders
    FILES shaders/wallpaper.frag
)
