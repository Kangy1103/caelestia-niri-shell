qml_module(CNS-components
    URI CNS.Components
    SOURCES
        animatedrepeater.cpp
        lazylistview.cpp
        wavyline.cpp
        buttonrow.cpp
        circularindicatormanager.cpp
        linearindicatormanager.cpp
        sparklineitem.cpp
        visualiserbars.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        CNS
    DEPENDENCIES
        CNS
)
