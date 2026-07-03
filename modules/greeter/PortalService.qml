pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string profileImage: ""
    property string _pendingUsername: ""

    Process {
        id: profileCheckProc
        running: false

        stdout: StdioCollector {
            id: profileStdio
        }

        onExited: {
            var text = profileStdio.text;
            if (text && text.trim().length > 0)
                root.profileImage = text.trim();
            else
                root.profileImage = "";
        }
    }

    function getGreeterUserProfileImage(username) {
        if (!username) {
            profileImage = "";
            return;
        }

        profileCheckProc.running = false;

        profileCheckProc.command = ["sh", "-c",
            `for f in "${GreetdSettings.greeterProfileCachePath}" /home/${username}/.face /home/${username}/.face.icon /var/lib/AccountsService/icons/${username}; do
                [ -f "$f" ] && [ -r "$f" ] && { echo "$f"; exit 0; }
            done
            exit 1`
        ];
        profileCheckProc.running = true;
    }
}
