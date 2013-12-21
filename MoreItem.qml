import QtQuick 2.0
import Ubuntu.Components 0.1

Rectangle {
    id: rectangle
    property var moreObj
    property int level: 0
    property Item parentComment
    property bool enabled: true

    property real padding: units.gu(0.8)
    property color primaryColor: "#f2f2f2"
    property color altColor: "#eaeaea"

    readonly property bool isLevelOdd: ((level % 2) === 1)
    readonly property int replyNo: moreObj ? moreObj.data.count : 0

    signal destroyItem()

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
                      moreObj.data.count.toLocaleString() + " More comments…"
                    :
                      "One more comment…"
              :
                "More comments…"
        fontSize: "x-small"
        font.weight: Font.Bold
        color: "#999999"
        opacity: rectangle.enabled ? 1 : 0.5
        anchors {
            top: parent.top
            topMargin: rectangle.padding
            left: parent.left
            leftMargin: rectangle.padding
        }
    }

    ActivityIndicator {
        id: activityIndicator
        visible: !rectangle.enabled
        height: label.height; width: height
        anchors {
            top: parent.top
            topMargin: rectangle.padding
            left: label.right
            leftMargin: rectangle.padding * 2
        }
        running: visible
    }

    MouseArea {
        enabled: rectangle.enabled
        anchors.fill: parent
        onClicked: {
            rectangle.enabled = false
            var moreConnObj = rectangle.moreObj.getMoreComments()
            moreConnObj.onSuccess.connect(function(){
                rectangle.destroyItem()
                for (var i = 0; i < moreConnObj.response.length; i++) {
                    rectangle.parentComment.appendReply(moreConnObj.response[i])
                }
            })
        }
    }
}
