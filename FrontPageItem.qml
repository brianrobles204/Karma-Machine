import QtQuick 2.0
import QtGraphicalEffects 1.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItems
import Ubuntu.Components.Popups 0.1
import "Utils/Misc.js" as MiscUtils
import "JSONListModel" as JSON

Item {
    id: frontPageItem
    property variant header
    property variant flickable: postFlickable
    property string title: (headerAddition.isOpen && header.flickable == postFlickable) ? "Karma Machine" : postList.subreddit == "" ? "FrontPage" : postList.subreddit

    function toggleHeaderAddition() {
        headerAddition.isOpen = !headerAddition.isOpen
    }

    function reloadFrontPage() {
        postList.loadSubreddit()
    }

    Flickable {
        id: postFlickable
        anchors.fill: parent
        contentHeight: postList.height
        property int prevContY: 0
        property bool contYHasBeenSet: false

        //To prevent the page from resetting the contentY when its flickables are changed
        onContentYChanged: {
            if(contentY !== -header.height || !contYHasBeenSet) {
                if(atYBeginning) contYHasBeenSet = true
                prevContY = contentY
            } else {
                contentY = prevContY
            }
        }

        Column {
            id: postList

            property var subredditObj
            readonly property string subreddit: subredditObj ? subredditObj.srName : ""
            property bool loading

            function _appendPosts(postsArray) {
                //Generate stuff here
                for (var i = 0; i < postsArray.length; i++) {
                    var component = Qt.createComponent("PostItem.qml")
                    var postItem = component.createObject(postList, {"internalModel": postsArray[i], "clip": true})
                    if (postItem == null) {
                        console.log("Error creating object")
                    }
                }
            }

            function _loadSubredditListing(srName, sort, paramObj) {
                clearListing()
                loading = true

                var metaSubredditObj
                if (subredditObj && subreddit === srName) {
                    metaSubredditObj = subredditObj
                } else {
                    metaSubredditObj = subredditObj = redditObj.getSubreddit(srName || "")
                }

                paramObj = paramObj || {}
                var subrConnObj = metaSubredditObj.getPostsListing(sort || 'hot', paramObj)
                subrConnObj.onSuccess.connect(function(response){
                    _appendPosts(subrConnObj.response)
                    loading = false
                })
            }

            function loadSubreddit(srName) {
                _loadSubredditListing(srName)
            }

            function loadParamObj(sort, paramObj) {
                _loadSubredditListing(subreddit, sort, paramObj)
            }

            function clearListing() {
                headerAddition.isOpen = false

                if(postList.children.length > 0) {
                    for (var i = 0; i < postList.children.length; i++) {
                        if(postList.children[i] !== headerAdditionRect) postList.children[i].destroy()
                    }
                }
                moreLoaderItem.spaceRect = null

                postFlickable.contentY = -frontPageItem.header.height - units.gu(0.25)
                headerAddition.isOpen = true
            }

            function loadMore() {
                var moreConnObj = subredditObj.getMoreListing()
                moreConnObj.onSuccess.connect(function(){
                    if(moreLoaderItem.spaceRect != null) {
                        moreLoaderItem.spaceRect.destroy()
                        moreLoaderItem.spaceRect = null
                    }
                    moreImage.visible = true
                    postList._appendPosts(moreConnObj.response)
                })
            }

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            Component.onCompleted: {
                redditNotifier.onAuthenticatingChanged.connect(function(){
                    var authStatus = redditNotifier.authenticating
                    if (authStatus === 'none' || authStatus === 'done') postList.loadSubreddit()
                });
            }

            Item {
                id: headerAdditionRect
                width: 1
                height: 0
                property bool isOpen
                Behavior on height {UbuntuNumberAnimation{}}
                function giveSpace() { isOpen = true; height = units.gu(12) }
                function hideSpace() { isOpen = false; height = 0 }
            }
        }
    }

    Item {
        id: headerAddition
        //color: "#f3f3f3"
        smooth: true
        //radius: units.gu(0.2)
        z: 100
        state: "headerClosed"

        property bool isOpen: false
        property bool enableBehavior
        property variant targetPostItem: null
        property real prevContentY: 0
        //property Flickable flickable: postFlickable

        Component.onCompleted: isOpen = true

        Connections {
            target: postFlickable
            onContentYChanged: {
                if(postFlickable.contentY <= -frontPageItem.header.height){
                    headerAddition.isOpen = true
                } else {
                    if(frontPageItem.header.flickable !== postFlickable && !headerAddition.isOpen) {
                        var deltaContentY = postFlickable.contentY - headerAddition.prevContentY
                        headerAddition.prevContentY = flickable.contentY
                        headerAddition.y = MiscUtils.clamp(headerAddition.y - deltaContentY, frontPageItem.header.height -units.gu(5.5), frontPageItem.header.height + units.gu(1))
                    }
                    headerAddition.isOpen = false
                }
            }
            onMovementEnded: {
                if(frontPageItem.header.flickable !== postFlickable && !headerAddition.isOpen) {
                    headerAddition.enableBehavior = true
                    if (headerAddition.y < frontPageItem.header.height - (headerAddition.height + units.gu(1))/2) headerAddition.y = frontPageItem.header.height -units.gu(5.5)
                    else headerAddition.y = frontPageItem.header.height + units.gu(1)
                    headerAddition.enableBehavior = false
                }
            }
        }

        states: [
            State {
                name: "headerOpen"
                PropertyChanges {
                    target: headerAddition
                    x: units.gu(1)
                    y: targetPostItem.y - postFlickable.contentY + units.gu(1)
                    width: parent.width - units.gu(2)
                    height: units.gu(10)
                }
            },
            State {
                name: "headerClosed"
                PropertyChanges {
                    target: headerAddition
                    x: units.gu(0)
                    y: {
                        if(frontPageItem.header.y <= -frontPageItem.header.height) {
                            return -units.gu(5.5)
                        } else {
                            return frontPageItem.header.y + frontPageItem.header.height
                        }
                    }
                    width: parent.width
                    height: units.gu(5.5)
                }
            }]

        MouseArea {
            anchors.fill: parent
            onClicked: frontPageItem.toggleHeaderAddition()
        }

        onIsOpenChanged: {
            if(!isOpen) {
                targetPostItem.hideSpace()
                state = "headerClosed"
                enableBehavior = false
                targetPostItem = null
            } else {
                if(postFlickable.contentY <= -frontPageItem.header.height) {
                    targetPostItem = postList.children[0]
                } else {
                    var beforePost = postList.childAt(1, postFlickable.contentY + frontPageItem.header.height)
                    targetPostItem = postList.childAt(1, beforePost.y + beforePost.height + units.gu(0.2))
                }
                targetPostItem.giveSpace()
                enableBehavior = true
                state = "headerOpen"
            }
        }

        Behavior on x {UbuntuNumberAnimation{}}
        Behavior on width {UbuntuNumberAnimation{}}
        Behavior on height {UbuntuNumberAnimation{}}
        Behavior on y {
            enabled: {
                if(header.flickable === postFlickable) {
                    //we want some animation when the header is moving, so the changes don't seem so abrupt
                    return !postList.children[0].isOpen
                } else {
                    return headerAddition.enableBehavior && !postList.children[0].isOpen
                }
            }
            UbuntuNumberAnimation{}
        }

        Rectangle {
            id: bgRect
            anchors.fill: parent
            anchors.margins: units.gu(1)
            radius: units.gu(0.2)
            smooth: true
            color: "#f3f3f3"

            Item {
                id: openHAddition
                visible: headerAddition.isOpen
                anchors {
                    fill: parent
                    margins: units.gu(1)
                }

                Label {
                    id: subredditSwitcher
                    text: postList.subreddit == "" ? "Frontpage" : postList.subreddit
                    anchors.left: parent.left
                    color: pressed ? UbuntuColors.orange : UbuntuColors.coolGrey
                    fontSize: "large"
                    property bool pressed:subMouseArea.pressed
                }

                Image{
                    id: subredditOpenIcon
                    anchors {
                        left: subredditSwitcher.right
                        leftMargin: units.gu(1)
                        verticalCenter: subredditSwitcher.verticalCenter
                    }
                    property bool isOpen: false
                    source: "media/ListArrow.png"
                    height: units.gu(1.25)
                    width: units.gu(0.75)
                    rotation: isOpen ? 270 : 90

                    Behavior on rotation { UbuntuNumberAnimation {} }
                }

                MouseArea {
                    id: subMouseArea
                    anchors{
                        top: subredditSwitcher.top
                        left: subredditSwitcher.left
                        right: headerDividerRect.left
                        bottom: subredditSwitcher.bottom
                    }

                    onClicked:  PopupUtils.open(subredditPopupComponent, subredditSwitcher)
                }

                Component {
                    id: subredditPopupComponent
                    Popover {
                        id: subredditPopover
                        onVisibleChanged: subredditOpenIcon.isOpen = visible
                        autoClose: true
                        Column {
                            id: subredditListColumn
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                            }
                            height: frontPageItem.height - (headerAddition.y + headerAddition.height + units.gu(5))
                            ListView {
                                id: subredditListView
                                clip: true
                                width: parent.width
                                height: parent.height
                                JSON.JSONListModel {
                                    id: subredditList
                                    source: ((storageHandler.modhash != "") && (storageHandler.defaultSubList == storageHandler.roDefaultsSubList)) ? "http://www.reddit.com/subreddits/mine/subscriber.json?limit=100&uh=" + storageHandler.modhash : ""
                                    query: "$.data.children[*]"

                                    onUpdated: {
                                        var subListArray = []
                                        for (var i = 1; i < model.count; i++) {
                                            var name = model.get(i).data.display_name
                                            var lowerCaseName = name.toLowerCase()
                                            var firstToUpName = lowerCaseName.substr(0, 1).toUpperCase() + lowerCaseName.substr(1)
                                            subListArray.push(firstToUpName)
                                        }
                                        var subList = subListArray.join()
                                        storageHandler.setProp('defaultSubList', subList)
                                    }
                                }

                                model: ListModel { id: subredditListModel }

                                Connections {
                                    target: storageHandler
                                    onDefaultSubListChanged: subredditListView.populateModel()
                                }
                                Component.onCompleted: populateModel()

                                function populateModel() {
                                    subredditListModel.clear()
                                    var listArray = storageHandler.defaultSubList.split(',').sort()
                                    listArray.unshift("<b>Frontpage</b>","<b>All</b>","<b>Custom...</b>")
                                    for (var i = 0; i < listArray.length; i++) {
                                        subredditListModel.append({"name": listArray[i]})
                                    }
                                }

                                delegate: ListItems.Standard {
                                    text: model.name
                                    onClicked: {
                                        PopupUtils.close(subredditPopover)
                                        if(model.name === "<b>Frontpage</b>"){
                                            postList.loadSubreddit()
                                        } else if (model.name === "<b>All</b>") {
                                            postList.loadSubreddit('All')
                                        }  else if (model.name === "<b>Custom...</b>") {
                                            PopupUtils.open(customSubRDialogComponent)
                                        } else {
                                            postList.loadSubreddit(model.name)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Component {
                     id: customSubRDialogComponent
                     Dialog {
                         id: customSubRDialog
                         title: "Enter a Custom Subreddit"
                         //text: "Subreddit of the Day:"

                         Component.onCompleted: customSubRTextField.forceActiveFocus()
                         function openSubreddit() {
                             var name = customSubRTextField.text
                             var lowerCaseName = name.toLowerCase()
                             var firstToUpName = lowerCaseName.substr(0, 1).toUpperCase() + lowerCaseName.substr(1)
                             postList.loadSubreddit(firstToUpName)
                             PopupUtils.close(customSubRDialog)
                         }

                         TextField {
                             id: customSubRTextField
                             placeholderText: 'pics'
                             primaryItem: Label {
                                 text: " r/"
                                 font.weight: Font.DemiBold
                                 anchors{
                                     top: parent.top
                                     topMargin: units.gu(0.75)
                                 }
                             }
                             hasClearButton: true
                             onAccepted: customSubRDialog.openSubreddit()
                         }
                         Item {
                             width: parent.width
                             height: childrenRect.height
                             Button {
                                 text: "Cancel"
                                 gradient: UbuntuColors.greyGradient
                                 onClicked: PopupUtils.close(customSubRDialog)
                                 anchors.left: parent.left
                             }
                             Button {
                                 text: "Enter"
                                 gradient: UbuntuColors.orangeGradient
                                 onClicked: customSubRDialog.openSubreddit()
                                 anchors.right: parent.right
                             }
                         }
                     }
                }

                Label {
                    id: sortingSwitcher
                    text: "What's Hot"
                    anchors{
                        left: parent.left
                        leftMargin: units.gu(0.2)
                        top: subredditSwitcher.bottom
                        topMargin: units.gu(0.6)
                    }
                    fontSize: "medium"
                    color: pressed ? UbuntuColors.orange : Theme.palette.selected.backgroundText
                    property bool pressed:sortingMouseArea.pressed
                }
                MouseArea {
                    id: sortingMouseArea
                    anchors{
                        top: sortingSwitcher.top
                        left: sortingSwitcher.left
                        right: headerDividerRect.left
                        bottom: sortingSwitcher.bottom
                    }

                    onClicked:  PopupUtils.open(sortingPopupComponent, sortingSwitcher)
                }
                Component {
                    id: sortingPopupComponent
                    Popover {
                        id: sortingPopover
                        Column {
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                            }
                            height: frontPageItem.height - (headerAddition.y + headerAddition.height + units.gu(5))
                            ListView {
                                clip: true
                                width: parent.width
                                height: parent.height
                                model: ListModel {
                                    id: sortingListModel
                                    ListElement {name: "What's Hot"; sort: "hot"; t: ""}
                                    ListElement {name: "What's New"; sort: "new"; t: ""}
                                    ListElement {name: "What's Rising"; sort: "rising"; t: ""}
                                    ListElement {name: "Top: Hour"; sort: "top"; t: "hour"}
                                    ListElement {name: "Top: Day"; sort: "top"; t: "day"}
                                    ListElement {name: "Top: Week"; sort: "top"; t: "week"}
                                    ListElement {name: "Top: Month"; sort: "top"; t: "month"}
                                    ListElement {name: "Top: Year"; sort: "top"; t: "year"}
                                    ListElement {name: "Top: All Time"; sort: "top"; t: "all"}
                                    ListElement {name: "Controversial: Hour"; sort: "controversial"; t: "hour"}
                                    ListElement {name: "Controversial: Day"; sort: "controversial"; t: "day"}
                                    ListElement {name: "Controversial: Week"; sort: "controversial"; t: "week"}
                                    ListElement {name: "Controversial: Month"; sort: "controversial"; t: "month"}
                                    ListElement {name: "Controversial: Year"; sort: "controversial"; t: "year"}
                                    ListElement {name: "Controversial: All Time"; sort: "controversial"; t: "all"}
                                }

                                delegate: ListItems.Standard {
                                    text: name
                                    onClicked: {
                                        PopupUtils.close(sortingPopover)
                                        sortingSwitcher.text = name
                                        var paramObj = {}
                                        if (t !== "") paramObj.t = t
                                        postList.loadParamObj(sort, paramObj);
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: headerDividerRect
                    anchors {
                        top: parent.top
                        topMargin: units.gu(0.5)
                        bottom: parent.bottom
                        bottomMargin: units.gu(0.5)
                        right: userContainer.left
                        rightMargin: units.gu(1)
                    }
                    width: units.gu(0.1)
                    color: "#dadada"
                }

                Item{
                    id: userContainer
                    height: childrenRect.height
                    width: Math.max(userImg.width, userName.width)
                    anchors{
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }

                    Image {
                        id: userImg
                        width: units.gu(4.5)
                        height: units.gu(4.5)
                        source: "media/user.png"
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                        }
                    }
                    Label {
                        id: userName
                        text: storageHandler.tmpUsername
                        anchors {
                            top: userImg.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                        fontSize: "small"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked:  PopupUtils.open(userPopupComponent, userContainer)
                    }
                    Component {
                        id: userPopupComponent
                        Popover {
                            id: userPopover
                            Column {
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                }
                                height: childrenRect.height
                                ListItems.Standard {
                                    text: 'Login'
                                    visible: storageHandler.modhash == ""
                                    onClicked: {
                                        PopupUtils.close(userPopover)
                                        PopupUtils.open(userDialogComponent)
                                    }
                                }
                                ListItems.Standard {
                                    text: 'Logout'
                                    visible: storageHandler.modhash != ""
                                    onClicked: {
                                        PopupUtils.close(userPopover)
                                        postList.loadSubreddit()
                                        actionHandler.logout()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: closedHAddition
                visible: !headerAddition.isOpen
                anchors {
                    fill: parent
                    margins: units.gu(1)
                }

                Label {
                    text: sortingSwitcher.text
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                    }
                }
            }
        }
    }

    Component {
         id: userDialogComponent
         Dialog {
             id: userDialog
             title: "Login to Reddit"
             text: "The Frontpage of the Internet"

             Component.onCompleted: usernameTextField.forceActiveFocus()
             function startLogin() {
                 if (usernameTextField.text == "" || passwordTextField.text == "") return true;
                 usernameTextField.focus = false
                 passwordTextField.focus = false
                 loginIndicator.visible = true
                 storageHandler.setProp('autologin', rememberCheckBox.checked)
                 var loginResponse = actionHandler.login(usernameTextField.text, passwordTextField.text)
             }

             TextField {
                 id: usernameTextField
                 placeholderText: 'Username'
                 hasClearButton: true
                 onAccepted: userDialog.startLogin()
             }
             TextField {
                 id: passwordTextField
                 placeholderText: 'Password'
                 hasClearButton: true
                 echoMode: TextInput.Password
                 onAccepted: userDialog.startLogin()
             }
             MouseArea {
                 anchors{
                     left: parent.left
                     leftMargin: units.gu(2)
                 }
                 width: childrenRect.width
                 height: childrenRect.height
                 onClicked: rememberCheckBox.checked = !rememberCheckBox.checked

                 CheckBox {
                     id: rememberCheckBox
                     checked: true
                     anchors.left: parent.left
                 }
                 Label {
                     text: "Remember me?"
                     anchors{
                         left: rememberCheckBox.right
                         leftMargin: units.gu(2)
                         verticalCenter: rememberCheckBox.verticalCenter
                     }
                 }
             }

             Item{ width: parent.width; height: units.gu(1)} //simple hack for extra spacing
             Item {
                 width: parent.width
                 height: childrenRect.height
                 Button {
                     text: "Cancel"
                     gradient: UbuntuColors.greyGradient
                     onClicked: PopupUtils.close(userDialog)
                     anchors.left: parent.left
                 }
                 ActivityIndicator {
                     id: loginIndicator
                     anchors{
                         right: loginButton.left
                         rightMargin: units.gu(1)
                         verticalCenter: loginButton.verticalCenter
                     }
                     running: true
                     visible: false
                 }

                 Button {
                     id: loginButton
                     text: "Login"
                     gradient: UbuntuColors.orangeGradient
                     onClicked: userDialog.startLogin()
                     anchors.right: parent.right

                     Connections {
                         target: actionHandler
                         onFinishedLoading: {
                             loginIndicator.visible = false
                             if (actionHandler.loginError == "") {
                                 postList.loadSubreddit()
                                 PopupUtils.close(userDialog)
                             } else {
                                 actionHandler.logout()
                                 usernameTextField.text = ""
                                 passwordTextField.text = ""
                                 userDialog.text = actionHandler.loginError
                             }
                         }
                     }
                 }
             }
         }
    }

    DropShadow {
        anchors.fill: headerAddition
        radius: units.gu(0.5)
        fast: true
        color: "#70000000"
        source: headerAddition
        verticalOffset: units.gu(0.1)
    }

    ActivityIndicator{
        anchors.centerIn: parent
        width: units.gu(5)
        height: units.gu(5)
        running: postList.loading || redditNotifier.authenticating === 'loading'
        z: -1
    }

    Item {
        id: moreLoaderItem
        anchors{
            bottom: parent.bottom
            bottomMargin: units.gu(2)
            horizontalCenter: parent.horizontalCenter
        }
        z: -1
        visible: ((overflow > 0) && (postFlickable.contentHeight >= parent.height) || spaceRect != null)
        width: units.gu(5)
        height: units.gu(5)

        property real loadMoreLength: units.gu(16)
        property real overflow: 0
        property variant spaceRect: null

        Connections {
            target: postFlickable

            onContentYChanged: {
                var pf = postFlickable
                if(pf.atYEnd && !pf.atYBeginning && (postFlickable.contentHeight >= parent.height)) {
                    moreLoaderItem.overflow = pf.contentY - pf.contentHeight + pf.height
                    if ((moreLoaderItem.overflow > moreLoaderItem.loadMoreLength) && !moreLoaderItem.spaceRect) {
                        moreLoaderItem.spaceRect = Qt.createQmlObject("import QtQuick 2.0; Item{width: 1; height: " + moreLoaderItem.loadMoreLength + "}", postList)
                        postList.loadMore()
                        moreImage.visible = false
                    }
                } else {
                    moreLoaderItem.overflow = 0
                }
            }
        }

        Image {
            id: moreImage
            source: "media/spinner.png"
            anchors.fill: parent
            rotation: parent.overflow
            smooth: true
        }

        ActivityIndicator{
            anchors.fill: parent
            running: true
            visible: !moreImage.visible
        }
    }
}
