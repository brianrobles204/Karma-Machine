import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItems
import Ubuntu.Components.Popups 0.1

Item {
    property var postObj: activePostObj

    function reload() {
        commentsList.loadComments()
    }

    function insertComment(commentObj) {
        commentsList.insertComment(commentObj)
    }

    height: childrenRect.height + units.gu(0.4)
    anchors { left: parent.left; right: parent.right }

    DescItem {
        id: descItem
    }

    Item{
        id: spaceAndCommentInfo
        height: units.gu(6)
        anchors{
            top: descItem.bottom
            left: parent.left
            right: parent.right
            leftMargin: units.gu(1)
            rightMargin: units.gu(1)
        }
        Image {
            id: commentIcon
            source: "media/Comments.png"
            height: units.gu(1.75)
            width: units.gu(1.75)
            anchors{
                left: parent.left
                leftMargin: units.gu(1.5)
                bottom: parent.bottom
                bottomMargin: units.gu(1)
            }
        }

        Label {
            id: commentLabel
            anchors {
                left: commentIcon.right
                leftMargin: units.gu(1)
                bottom: parent.bottom
                bottomMargin: units.gu(1)
            }
            fontSize: "small"
            font.weight: Font.DemiBold
            text: postObj ? postObj.data.num_comments.toLocaleString() : ""
        }

        AbstractButton{
            id: commentSorting
            height: units.gu(5)
            width: sortingLabel.width + units.gu(4)
            anchors {
                right: parent.right
                rightMargin: units.gu(1.5)
                bottom: parent.bottom
                bottomMargin: units.gu(1)
            }
            onClicked: PopupUtils.open(sortingPopupComponent, commentSorting)

            Image{
                id: openIcon
                anchors.right: parent.right
                anchors.verticalCenter: sortingLabel.verticalCenter
                property bool isOpen: false
                source: "media/ListArrow.png"
                height: units.gu(1.25)
                width: units.gu(0.75)
                rotation: isOpen ? 270 : 90

                Behavior on rotation { UbuntuNumberAnimation {} }
            }
            Label {
                id: sortingLabel
                text: dict[settingsHandler.commentsSort]
                fontSize: "small"
                font.weight: Font.DemiBold
                anchors.right: openIcon.left
                anchors.rightMargin: units.gu(1)
                anchors.bottom: parent.bottom
                property variant dict: {'confidence': 'Best',
                                        'top': 'Top',
                                        'new': 'New',
                                        'hot': 'Hot',
                                        'old': 'Old',
                                        'controversial': 'Controversial'}
            }
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

    ListView {
        id: commentsList

        property var postObj: activePostObj
        property bool loading: true
        property var activeCommentObj: []

        function insertComment(commentObj) {
            var component = Qt.createComponent("CommentItem.qml")
            var commentItem = component.createObject(commentsList, { commentObj: commentObj, level: 1 })
            var spaceRect = Qt.createQmlObject("import QtQuick 2.0; Item{width: 1; height: units.gu(1.6)}", commentsList)

            activePostObj.data.num_comments += 1
            activePostObjChanged()
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
                    commentsListModel.append({kind: activeCommentObj[i].kind, level: 1, index: i})
                }
                setPostTimer.postObj = commentsConnObj.response[0]
                setPostTimer.restart()
            });
        }

        model: ListModel {
            id: commentsListModel
        }

        delegate: Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            source: {
                if(kind === "t1") {
                    return "CommentItem.qml"
                } else if (kind === "more") {
                    return "MoreItem.qml"
                }
            }
            Component.onCompleted: {
                item.level = level
                if(kind === "t1") {
                    item.commentObj = commentsList.activeCommentObj[index]
                } else if (kind === "more") {
                    item.moreObj = commentsList.activeCommentObj[index]
                }
            }
        }

        anchors {
            top: spaceAndCommentInfo.bottom
            topMargin: units.gu(0.5)
            left: parent.left
            right: parent.right
            leftMargin: units.gu(1.5)
            rightMargin: units.gu(1.5)
        }
        height: count > 0 ? contentHeight : 0
        interactive: false
        spacing: units.gu(1.6)

        Timer {
            id: setPostTimer
            property var postObj
            interval: 1
            onTriggered: activePostObj = postObj
        }

        Connections {
            target: settingsHandler
            onCommentsSortChanged: {
                commentsList.loadComments()
            }
        }
    }

    ActivityIndicator{
        anchors {
            top: commentsList.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: units.gu(3.5)
        height: units.gu(3.5)
        running: commentsList.loading
    }
}
