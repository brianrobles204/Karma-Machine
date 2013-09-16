import QtQuick 2.0
import Ubuntu.Components 0.1

Flickable {
    id: swipeBox
    width: parent.width

    flickableDirection: Flickable.HorizontalFlick
    property real maxFlickDist: units.gu(8)
    property bool isPressed: false
    interactive: false

    signal swipedLeft
    signal swipedRight
    signal clicked

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onPressed: swipeBox.interactive = true
        onReleased: swipeBox.interactive = false
        onCanceled: if(!swipeBox.isPressed) swipeBox.interactive = false
    }

    onContentXChanged: {
        if(contentX > maxFlickDist || contentX < -maxFlickDist) {
            interactive = false
            contentX = contentX >= 0 ? maxFlickDist : -maxFlickDist
            contentX >= 0 ? swipedLeft() : swipedRight()
        }

        // Handling an edge case (bug?) where setting contentX causes the whole thing to freeze
        if ((contentX === maxFlickDist || contentX === -maxFlickDist) && !isPressed) {
            console.log("edge case")
            returnToBounds()
        }
    }
    onDragStarted: isPressed = true
    onDragEnded: {
        interactive = false
        isPressed = false
    }

    Component.onCompleted: {
        mouseArea.clicked.connect(clicked)
    }
}

