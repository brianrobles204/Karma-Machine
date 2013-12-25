import QtQuick 2.0
import Ubuntu.Components 0.1

MouseArea {
    id: headerMouseArea
    anchors.fill: parent
    z: -1
    property bool pressed: false
    property string title: bigTitle
    property string subTitle: littleTitle

    property Gradient pressedGradient: Gradient {
        GradientStop { position: 0.0; color: "#D9722D" }
        GradientStop { position: 1.0; color: "#D9722D" }
    }

    Rectangle {
        id: headerRect
        anchors.fill: parent
        z: -1
        gradient: parent.pressed ? parent.pressedGradient : UbuntuColors.orangeGradient

        property real contentHeight: units.gu(7.5)
        property int fontWeight: Font.Light
        property string fontSize: "x-large"
        property string subFontSize: "large"
        property color textColor: "#fafafa"
        property real textLeftMargin: units.gu(2)

        property string title: headerMouseArea.title
        property string subTitle: headerMouseArea.subTitle
        property bool linkState: linkOpen

        Item {
            id: headerContents
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: headerRect.contentHeight
            visible: !isPhone

            Label {
                id: headerLabel
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: headerRect.textLeftMargin
                }
                text: headerRect.title
                font.weight: headerRect.fontWeight
                fontSize: headerRect.fontSize
                color: headerRect.textColor
            }

            Label {
                id: headerSubLabel
                anchors {
                    left: headerLabel.right
                    leftMargin: units.gu(1.35)
                    right: headerArrow.left
                    rightMargin: units.gu(1.35)
                    bottom: headerLabel.bottom
                    bottomMargin: units.gu(0.35)
                }
                text: headerRect.subTitle
                font.weight: headerRect.fontWeight
                fontSize: headerRect.subFontSize
                elide: Text.ElideRight
                color: headerRect.textColor
            }
            Image {
                id: headerArrow
                anchors {
                    right: parent.right
                    rightMargin: units.gu(1.35)
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: units.gu(0.2)
                }
                visible: canBeToggled
                source: "media/ui/header_toggle.png"
                rotation: headerRect.linkState ? 180 : 0
                Behavior on rotation {UbuntuNumberAnimation{}}
            }
        }
    }

    onClicked: {
        if(isPhone) {
            if(currentPage == frontPage) {
                frontPageItem.toggleHeaderAddition()
            }
        } else {
            togglePostPageItem()
        }
    }

    onPressed: pressed = true
    onReleased: pressed = false
}
