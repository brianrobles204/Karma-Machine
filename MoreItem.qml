import QtQuick 2.0
import Ubuntu.Components 0.1

Rectangle {
    id: rectangle
    property var moreObj
    property int level: 0
    property real padding: units.gu(0.8)

    property color primaryColor: "#f2f2f2"
    property color altColor: "#eaeaea"

    readonly property bool isLevelOdd: ((level % 2) === 1)

    anchors {
        left: parent.left
        leftMargin: units.gu(1)
        right: parent.right
        rightMargin: level === 1 ? units.gu(1) : 0
    }

    height: label.height + 2*padding
    color: isLevelOdd ? primaryColor : altColor
    radius: units.gu(0.6)

    Label {
        id: label
        text: moreObj ?
                  moreObj.data.count > 1 ?
                      moreObj.data.count.toLocaleString() + " More Comments…"
                    :
                      "One More Comment…"
              :
                "More Comments…"
        fontSize: "x-small"
        font.weight: Font.Bold
        color: "#999999"
        anchors {
            top: parent.top
            topMargin: rectangle.padding
            left: parent.left
            leftMargin: rectangle.padding
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            var moreConnObj = rectangle.moreObj.getMoreComments()
            moreConnObj.onSuccess.connect(function(){
                console.log(JSON.stringify(moreConnObj.response))
            })
        }
    }
}
