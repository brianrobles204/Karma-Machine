import QtQuick 2.0
import Ubuntu.Components 0.1

Image {
    property string icon
    property real size: units.gu(1.5)

    source: "media/emblems/" + icon + ".svg"
    width: visible ? size : 0;
    height: size
    sourceSize { width: size; height: size }
}
