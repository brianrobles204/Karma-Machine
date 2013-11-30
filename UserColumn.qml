import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItems

Column {
    id: userColumn

    property variant users
    property int selectedIndex: 0
    property bool loading: false

    readonly property bool hasUserStored: users.length > 0
    readonly property bool isLoggedIn: selectedIndex >= 0 && hasUserStored

    signal userSwitch()
    signal userDelete( int deletedIndex )
    signal userAdd()

    anchors { left: parent.left; right: parent.right}
    height: childrenRect.height

    ListItems.Standard {
        id: profileItem
        text: "Profile"
        icon: Image {
            source: "media/user-actions/profile.png"
        }
        visible: userColumn.isLoggedIn && !userColumn.loading
    }

    ListItems.Standard {
        id: messagesItem
        text: "Messages"
        icon: Image {
            source: "media/user-actions/messages.png"
        }
        visible: userColumn.isLoggedIn && !userColumn.loading
    }

    ListItems.Standard {
        id: savedItem
        text: "Saved"
        icon: Image {
            source: "media/user-actions/saved.png"
        }
        visible: userColumn.isLoggedIn && !userColumn.loading
    }

    ListItems.Empty {
        id: anonItem

        property real padding: units.gu(2)

        visible: !userColumn.isLoggedIn && !userColumn.loading
        height:{
            try {
                return !userColumn.loading ? __contents.childrenRect.height + padding*2 : -1
            } catch (e) {
                return units.gu(18)
            }
        }

        Image {
            id: anonImage
            anchors { top: parent.top; topMargin: anonItem.padding; horizontalCenter: parent.horizontalCenter }
            height: units.gu(7)
            source: 'media/user-actions/noSignal.png'
            fillMode: Image.PreserveAspectFit
            opacity: 0.6
        }

        Label {
            anchors { top: anonImage.bottom; topMargin: anonItem.padding; horizontalCenter: parent.horizontalCenter }
            text: "You are currently logged out."
            fontSize: "large"
        }
    }

    ListItems.Empty {
        id: loadingItem

        property real padding: units.gu(2)

        visible: userColumn.loading
        height:{
            try {
                return userColumn.loading ? __contents.childrenRect.height + padding*2 : -1
            } catch (e) {
                return units.gu(13)
            }
        }

        ActivityIndicator {
            id: loadingIndicator
            anchors { top: parent.top; topMargin: anonItem.padding; horizontalCenter: parent.horizontalCenter }
            running: true
        }

        Label {
            anchors { top: loadingIndicator.bottom; topMargin: anonItem.padding; horizontalCenter: parent.horizontalCenter }
            text: "Loading…"
        }
    }

    ListItems.Standard {
        id: managerItem

        property bool expanded: false

        signal internalPressed

        text: "Manage users"
        visible: userColumn.hasUserStored
        enabled: !userColumn.loading
        onInternalPressed: expanded = !expanded
        Component.onCompleted: __mouseArea.onClicked.connect(internalPressed)

        control: Item {
            height: childrenRect.height; width: childrenRect.width
            opacity: managerItem.enabled ? 1.0 : 0.5

            Label {
                id: managerControlLabel

                property color defaultColor: "#000000"
                property color anonColor: Theme.palette.normal.backgroundText
                property string anonString: "[anonymous]"
                property string loadingString: "loading…"

                text: !userColumn.loading ? userColumn.isLoggedIn ? userColumn.users[userColumn.selectedIndex] : anonString : loadingString
                color: userColumn.isLoggedIn && !userColumn.loading ? defaultColor : anonColor
                fontSize: "small"
                font.bold: managerItem.expanded
            }

            Image {
                id: managerControlIcon
                anchors { left: managerControlLabel.right; leftMargin: managerItem.__contentsMargins}
                source: "media/user-actions/ListItemProgressionArrow.png"
                rotation: managerItem.expanded ? 270 : 90
                width: implicitWidth / 1.5
                height: implicitHeight / 1.5

               Behavior on rotation { UbuntuNumberAnimation{} }
            }
        }
    }

    Repeater {
        id: accountRepeater

        model: userColumn.users

        Rectangle {
            property int expandedHeight: units.gu(5)

            color: Qt.lighter(Theme.palette.normal.base)
            height: managerItem.expanded ? expandedHeight : -1
            width: parent.width
            visible: height != -1
            opacity: height / expandedHeight

            Behavior on height { UbuntuNumberAnimation { duration: UbuntuAnimation.SnapDuration } }

            ListItems.Standard {
                id: accountItem

                readonly property string selectedModelData: "<b>" + modelData + "</b>"
                readonly property bool isSelected: index === userColumn.selectedIndex
                signal internalPressed

                function triggerCallback() {
                    userColumn.selectedIndex = index
                    managerItem.expanded = false
                    userColumn.userSwitch()
                }

                function deleteCallback() {
                    managerItem.expanded = false
                    userColumn.userDelete(index)
                }

                height: parent.height
                text: isSelected ? selectedModelData : modelData
                __contentsMargins: units.gu(3.5) //internal hack to increase left text padding

                control: Image {
                    source: "media/user-actions/delete.png"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: accountItem.deleteCallback()
                    }
                }

                onInternalPressed: triggerCallback()
                Component.onCompleted: __mouseArea.onClicked.connect(internalPressed)
            }
        }
    }

    Rectangle {
        id: actionItem

        property int padding: units.gu(1)
        property int expandedHeight: childrenRect.height + padding*2

        color: userColumn.hasUserStored ? Qt.lighter(Theme.palette.normal.base) : "transparent"
        width: parent.width
        height: (managerItem.expanded || !userColumn.hasUserStored) ? expandedHeight : -1
        visible: height != -1
        opacity: height / expandedHeight

        Behavior on height { UbuntuNumberAnimation { duration: UbuntuAnimation.SnapDuration } }

        Button {
            anchors {
                top: parent.top
                topMargin: parent.padding
                right: parent.right
                rightMargin: parent.padding
            }
            text: "Add user"
            enabled: !userColumn.loading
            onTriggered: userColumn.userAdd()
        }
        Button {
            anchors {
                top: parent.top
                topMargin: parent.padding
                left: parent.left
                leftMargin: parent.padding
            }
            text: "Go anonymous"
            gradient: UbuntuColors.greyGradient
            visible: userColumn.isLoggedIn
            onTriggered: {
                userColumn.selectedIndex = -1
                managerItem.expanded = false
                userColumn.userSwitch()
            }
        }
    }
}
