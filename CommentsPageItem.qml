import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItems
import Ubuntu.Components.Popups 0.1

Column {
    property var postObj: activePostObj
    property real beginningCommentsPos: descItem.height + commentInfo.height

    function reload() {
        commentsRepeater.loadComments()
    }

    function insertComment(commentObj) {
        commentsRepeater.insertComment(commentObj)
    }

    height: childrenRect.height + units.gu(2.5)
    anchors { left: parent.left; right: parent.right }
    spacing: units.gu(1.5)

    DescItem {
        id: descItem
    }

    Item{
        id: commentInfo
        height: units.gu(4)
        anchors{
            left: parent.left
            right: parent.right
            leftMargin: units.gu(1.6)
            rightMargin: units.gu(1.6)
        }
        Image {
            id: commentIcon
            source: "media/Comments.png"
            anchors{ left: parent.left; bottom: parent.bottom }
            height: units.gu(1.75); width: units.gu(1.75)
        }

        Label {
            id: commentLabel
            text: postObj ? postObj.data.num_comments.toLocaleString() : ""
            fontSize: "small"; font.weight: Font.DemiBold
            anchors { left: commentIcon.right; leftMargin: units.gu(1); bottom: parent.bottom }
        }

        AbstractButton{
            id: commentSorting
            anchors { right: parent.right; bottom: parent.bottom }
            height: units.gu(5)
            width: sortingLabel.width + units.gu(4)
            onClicked: PopupUtils.open(sortingPopupComponent, commentSorting)

            Image{
                id: openIcon
                property bool isOpen: false
                source: "media/ListArrow.png"
                anchors.right: parent.right; anchors.verticalCenter: sortingLabel.verticalCenter
                height: units.gu(1.25); width: units.gu(0.75)
                rotation: isOpen ? 270 : 90

                Behavior on rotation { UbuntuNumberAnimation {} }
            }
            Label {
                id: sortingLabel
                text: dict[settingsHandler.commentsSort]
                fontSize: "small"; font.weight: Font.DemiBold
                anchors.right: openIcon.left; anchors.rightMargin: units.gu(1); anchors.bottom: parent.bottom
                property var dict: {'confidence': 'Best',
                                        'top': 'Top',
                                        'new': 'New',
                                        'hot': 'Hot',
                                        'old': 'Old',
                                        'controversial': 'Controversial'}
            }
        }

        Component {
            id: sortingPopupComponent
            Popover {
                id: sortingPopover
                onVisibleChanged: openIcon.isOpen = visible
                Column {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: childrenRect.height
                    ListView {
                        clip: true
                        width: parent.width
                        height: childrenRect.height
                        model: ListModel {
                            id: sortingListModel
                            ListElement {name: "Best"; sort: "confidence"}
                            ListElement {name: "Top"; sort: "top"}
                            ListElement {name: "New"; sort: "new"}
                            ListElement {name: "Hot"; sort: "hot"}
                            ListElement {name: "Old"; sort: "old"}
                            ListElement {name: "Controversial"; sort: "controversial"}
                        }

                        delegate: ListItems.Standard {
                            text: settingsHandler.commentsSort !== sort ? name : "<b>" + name + "</b>"
                            onClicked: {
                                PopupUtils.close(sortingPopover)
                                settingsHandler.commentsSort = sort
                                sortingLabel.text = name
                            }
                        }
                    }
                }
            }
        }
    }

    Repeater {
        id: commentsRepeater

        property var postObj: activePostObj
        property bool loading: true
        property var activeCommentObj: []

        function insertComment(commentObj) {
            activeCommentObj.push(commentObj)
            commentsListModel.insert(0, {kind: commentObj.kind, index: activeCommentObj.length - 1})
        }

        function loadComments() {
            commentsListModel.clear()
            loading = true
            activeCommentObj = []
            if (postObj == undefined) return

            var commentsConnObj = postObj.getComments(settingsHandler.commentsSort, {limit: 25})
            commentsConnObj.onSuccess.connect(function(){
                loading = false
                for (var i = 0; i < commentsConnObj.response[1].length; i++) {
                    activeCommentObj.push(commentsConnObj.response[1][i])
                    commentsListModel.append({kind: activeCommentObj[i].kind, index: i})
                }
                setPostTimer.postObj = commentsConnObj.response[0]
                setPostTimer.restart()
            });
        }

        function appendReply(replyObj) {
            activeCommentObj.push(replyObj)
            commentsListModel.append({kind: replyObj.kind, index: activeCommentObj.length - 1})
        }

        model: ListModel {
            id: commentsListModel
        }

        Loader {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: units.gu(1.5)
                rightMargin: units.gu(1.5)
            }
            source: {
                if(kind === "t1") {
                    return "CommentItem.qml"
                } else if (kind === "more") {
                    return "MoreItem.qml"
                } else {
                    return ""
                }
            }
            Component.onCompleted: {
                item.level = 1
                if(kind === "t1") {
                    item.commentObj = commentsRepeater.activeCommentObj[index]
                } else if (kind === "more") {
                    item.moreObj = commentsRepeater.activeCommentObj[index]
                    item.parentComment = commentsRepeater
                    item.onDestroyItem.connect(function(){
                        commentsListModel.remove(commentsListModel.count - 1)
                    })
                }
            }
        }
    }

    Timer {
        id: setPostTimer
        property var postObj
        interval: 1
        onTriggered: activePostObj = postObj
    }

    Connections {
        target: settingsHandler
        onCommentsSortChanged: {
            commentsRepeater.loadComments()
        }
    }

    ActivityIndicator{
        anchors {
            horizontalCenter: parent.horizontalCenter
        }
        width: units.gu(3.5)
        height: visible ? units.gu(3.5) : 1
        running: commentsRepeater.loading
        visible: running
    }
}
