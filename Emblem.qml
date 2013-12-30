import QtQuick 2.0
import Ubuntu.Components 0.1

Image {
    property string icon

    source: "media/emblems/" + icon + ".svg"
    width: visible ? units.gu(1.2) : 0;
    height: units.gu(1.2)
    sourceSize { width: units.gu(1.2); height: units.gu(1.2) }
}
