import QtQuick 2.0
import Ubuntu.Components 0.1

Row {
    property var thingObj
    property real padding: units.gu(1)
    property real lineHeight: units.gu(1.8) //Approximate height of one line of text, for alignment
    property bool animate: true

    readonly property bool empty: {
        for(var i = 0; i < children.length; i++) {
            if (children[i].visible) return false
        }
        return true
    }
    readonly property real emblemTopMargin: padding + (lineHeight - height)/ 2

    anchors {
        top: parent.top
        topMargin: animate ? !empty ? emblemTopMargin : 0 : emblemTopMargin
        right: parent.right
        rightMargin: animate ? !empty ? padding : 0 : padding
    }
    height: animate ? !empty ? childrenRect.height : 0 : childrenRect.height
    spacing: units.gu(0.6)

    add: Transition {
        UbuntuNumberAnimation { property: "scale"; from: 0; to: 1 }
    }

    Behavior on height { UbuntuNumberAnimation {} }

    Emblem {
        icon: "edited"
        visible: thingObj === undefined || thingObj.data.edited
    }

    Emblem {
        icon: "gilded"
        visible: thingObj === undefined || ( thingObj.data.hasOwnProperty("gilded") && thingObj.data.gilded )

        Label {
            anchors { bottom: parent.bottom; bottomMargin: -units.gu(0.25); right: parent.right }
            text: thingObj !== undefined && thingObj.data.hasOwnProperty("gilded") ? thingObj.data.gilded > 1 ? thingObj.data.gilded : "" : 0
            fontSize: "x-small"
            font.bold: true
            color: "#877332"
        }
    }

    Emblem {
        id: upvoteEmblem
        icon: "upvote"

        property real loadingOpacity

        visible: thingObj === undefined || thingObj.priv.likesLocal === true
        opacity: 1.0

        SequentialAnimation on loadingOpacity {
            running: upvoteEmblem.state === "LOADING"
            loops: Animation.Infinite
            NumberAnimation {
                from: 0.2; to: 0.8
                duration: UbuntuAnimation.BriskDuration
            }
            NumberAnimation {
                from: 0.8; to: 0.2
                duration: UbuntuAnimation.BriskDuration
            }
        }

        states: State {
            name: "LOADING"
            when: thingObj !== undefined && thingObj.priv.likesLoading && thingObj.priv.likesLocal === true
            PropertyChanges { target: upvoteEmblem; opacity: upvoteEmblem.loadingOpacity }
        }

        transitions: Transition {
            UbuntuNumberAnimation { property: "opacity" }
        }
    }

    Emblem {
        id: downvoteEmblem
        icon: "downvote"

        property real loadingOpacity

        visible: thingObj === undefined || thingObj.priv.likesLocal === false
        opacity: 1.0

        SequentialAnimation on loadingOpacity {
            running: downvoteEmblem.state === "LOADING"
            loops: Animation.Infinite
            NumberAnimation {
                from: 0.2; to: 0.8
                duration: UbuntuAnimation.BriskDuration
            }
            NumberAnimation {
                from: 0.8; to: 0.2
                duration: UbuntuAnimation.BriskDuration
            }
        }

        states: State {
            name: "LOADING"
            when: thingObj !== undefined && thingObj.priv.likesLoading && thingObj.priv.likesLocal === false
            PropertyChanges { target: downvoteEmblem; opacity: downvoteEmblem.loadingOpacity }
        }

        transitions: Transition {
            UbuntuNumberAnimation { property: "opacity" }
        }
    }
}
