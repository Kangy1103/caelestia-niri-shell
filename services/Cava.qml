pragma Singleton

import CNS.Config
import CNS.Services
import Quickshell

Singleton {
    id: root

    readonly property alias provider: provider
    readonly property alias values: provider.values

    CavaProvider {
        id: provider

        bars: GlobalConfig.services.visualiserBars
    }
}
