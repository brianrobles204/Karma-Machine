import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItems
import Ubuntu.Components.Popups 0.1

Item {
    property variant internalModel
    height: childrenRect.height + units.gu(0.4)
    anchors{
        left: parent.left
        right: parent.right
    }

    function reload() {
        commentsFeed.reload()
    }

    DescItem {
        id: descItem
        internalModel: parent.internalModel
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
            text: internalModel ? internalModel.data.num_comments : ""
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
                text: dict[commentsFeed.sort]
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
                        text: name
                        onClicked: {
                            PopupUtils.close(sortingPopover)
                            storageHandler.setProp('commentsSort', sort)
                            sortingLabel.text = name
                            //commentsFeed.sort = sort
                        }
                    }
                }
            }
        }
    }

    CommentsModel {
        id: commentsFeed
        article: internalModel ? internalModel.data.id : ""
        limit: 40
        sort: storageHandler.commentsSort

        onAppendCalled: {
            var cModel = get(count -1)
            var height = createComments(cModel, 1)
        }
        function createComments(cModel, level) {
            if(cModel.kind == "t1"){
                var component = Qt.createComponent("CommentsItem.qml")
                var commentItem = component.createObject(commentsColumn, {"internalModel": cModel})
                if(commentItem == null) {
                    console.log("Error creating object")
                }

                commentItem.anchors.leftMargin = units.gu(1) * level
                var isLevelEven = ((level % 2) === 0)
                if (isLevelEven) commentItem.bgRect.color = "#efefef"

                var addToHeight = commentItem.height + units.gu(0.6)
                if(cModel.data.replies.data !== undefined) {
                    var childComments = cModel.data.replies.data.children
                    for (var i = 0; i < childComments.length; i++){
                        addToHeight += createComments(childComments[i], level + 1)
                    }
                }

                var spaceRect = Qt.createQmlObject("import QtQuick 2.0; Item{width: 1; height: units.gu(0.6)}", commentsColumn)
                if (level === 1) spaceRect.height = units.gu(1)
                commentItem.bgRect.height = addToHeight - units.gu(0.6)

                return addToHeight
            } else {
                // TODO: "More" kind of comments
                return 0
            }
        }

        onStatusChanged: {
            if (!status) {
                if(commentsColumn.children.length > 0) {
                    for (var i = 0; i < commentsColumn.children.length; i++) {
                        commentsColumn.children[i].destroy()
                    }
                }
            }
        }
    }

    Column {
        id: commentsColumn
        anchors {
            top: spaceAndCommentInfo.bottom
            topMargin: units.gu(0.5)
            left: parent.left
            right: parent.right
            leftMargin: units.gu(1.5)
            rightMargin: units.gu(1.5)
        }
    }

    ActivityIndicator{
        anchors {
            top: commentsColumn.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: units.gu(3.5)
        height: units.gu(3.5)
        running: commentsFeed.status !== true
    }
}
