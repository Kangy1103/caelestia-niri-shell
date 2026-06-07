import qs.utils
import Quickshell
import Quickshell.Io

JsonObject {
    property string wallpaperDir: `${Paths.pictures}/Wallpapers`
    property string wallpaper: ""  // Current wallpaper path - set this in shell.json
    property string sessionGif: `${Quickshell.shellDir}/assets/kurukuru.gif`
    property string mediaGif: `${Quickshell.shellDir}/assets/bongocat.gif`
}
