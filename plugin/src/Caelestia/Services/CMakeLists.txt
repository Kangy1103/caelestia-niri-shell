qml_module(CNS-services
    URI CNS.Services
    SOURCES
        service.hpp service.cpp
        serviceref.hpp serviceref.cpp
        beattracker.hpp beattracker.cpp
        audiocollector.hpp audiocollector.cpp
        audioprovider.hpp audioprovider.cpp
        cavaprovider.hpp cavaprovider.cpp
        tickingservice.cpp
        sensorslib.cpp
        usagefmt.cpp
        cpu.cpp
        gpu.cpp
        memory.cpp
        diskinfo.cpp
        storage.cpp
        lyriccandidate.cpp
        lyrics.cpp
        sysmonitor.hpp sysmonitor.cpp
        sessionmanager.hpp sessionmanager.cpp
    LIBRARIES
        Qt::DBus
        PkgConfig::Pipewire
        PkgConfig::Aubio
        PkgConfig::Cava
        Sensors::Sensors
        CNS
        CNS-config
        CNS-internal
)
