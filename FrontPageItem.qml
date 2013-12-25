import QtQuick 2.0
import QtGraphicalEffects 1.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItems
import Ubuntu.Components.Popups 0.1
import "JSONListModel" as JSON
import "Utils/Misc.js" as MiscUtils
import "QReddit/QRHelper.js" as QRHelper

Item {
    id: frontPageItem
    property variant header
    property variant flickable: postFlickable
    property string title: (headerAddition.isOpen && header.flickable == postFlickable) ? "Karma Machine" : postList.subreddit == "" ? "FrontPage" : postList.subreddit

    function toggleHeaderAddition() {
        headerAddition.isOpen = !headerAddition.isOpen
    }

    function reloadPage() {
        postList.loadSubreddit(postList.subreddit, true)
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

            readonly property string subreddit: subredditObj ? subredditObj.srName : ""
            readonly property bool containsPosts: children.length > 1
            property string _sort: "hot"
            property string _time: ""

            property var subredditObj
            property bool loading

            function _appendPosts(postsArray) {
                //Generate stuff here
                for (var i = 0; i < postsArray.length; i++) {
                    var component = Qt.createComponent("PostItem.qml")
                    var postItem = component.createObject(postList, {"postObj": postsArray[i], "clip": true})
                    if (postItem == null) {
                        console.log("Error creating object")
                    }
                }
            }

            function _loadSubredditListing(srName, sort, paramObj) {
                _sort = sort
                _time = paramObj.t || ""
                clearListing()
                loading = true

                var metaSubredditObj
                if (subredditObj && subreddit === srName) {
                    metaSubredditObj = subredditObj
                } else {
                    metaSubredditObj = subredditObj = redditObj.getSubredditObj(srName || "")
                }

                paramObj = paramObj || {}
                var subrConnObj = metaSubredditObj.getPostsListing(sort || 'hot', paramObj)
                subrConnObj.onSuccess.connect(function(response){
                    _appendPosts(subrConnObj.response)
                    loading = false
                })
            }

            function loadSubreddit(srName, force) {
                srName = srName || ""
                if(srName === subreddit && containsPosts && !force) return true
                var paramObj = {}
                if (_time !== "") paramObj.t = _time
                _loadSubredditListing(srName, _sort, paramObj)
            }

            function loadParamObj(sort, paramObj, force) {
                if(sort === _sort && (paramObj.t || "" === _time) && !force) return true
                _loadSubredditListing(subreddit, sort, paramObj)
            }

            function clearListing() {
                activePostObj = undefined
                headerAddition.isOpen = false

                if(containsPosts) {
                    for (var i = 0; i < children.length; i++) {
                        if(children[i] !== headerAdditionRect) children[i].destroy()
                    }
                }
                moreLoaderItem.spaceRect = null

                postFlickable.contentY = -frontPageItem.header.height - 1
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

            Item {
                id: headerAdditionRect
                property bool isOpen

                function giveSpace() { isOpen = true; height = units.gu(12) }
                function hideSpace() { isOpen = false; height = 0 }

                width: 1; height: 0

                Behavior on height {UbuntuNumberAnimation{}}
            }
        }
    }

    Item {
        id: headerAddition
        smooth: true
        z: 100
        state: "headerClosed"

        property bool isOpen: false
        property bool enableBehavior
        property variant targetPostItem: null
        property real prevContentY: 0

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
                            return frontPageItem.header.y + frontPageItem.header.height + units.gu(1)
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

                    property bool pressed:subMouseArea.pressed
                    property ListModel model: !redditNotifier.subscribedLoading ? QRHelper.arrayToListModel(redditObj.getSubscribedArray()) : QRHelper.arrayToListModel([""])

                    text: postList.subreddit == "" ? "Frontpage" : postList.subreddit
                    anchors.left: parent.left
                    color: pressed ? UbuntuColors.orange : UbuntuColors.coolGrey
                    fontSize: "large"
                }

                Image{
                    id: subredditOpenIcon
                    anchors {
                        left: subredditSwitcher.right
                        leftMargin: units.gu(1)
                        verticalCenter: subredditSwitcher.verticalCenter
                    }
                    property bool isOpen: false
                    source: "media/ui/item_toggle.png"
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
                        autoClose: true
                        onVisibleChanged: subredditOpenIcon.isOpen = visible
                        //In the future, this ListView will have to be replaced with a Column and Repeaters/ListView
                        //To allow for MultiReddits or Favorites, etc
                        ListView {
                            id: subredditListView

                            property real maxHeight: frontPageItem.height - (headerAddition.y + headerAddition.height + units.gu(5))
                            property real realHeight: count > 0 ? contentHeight : 1

                            clip: true
                            width: parent.width
                            height: maxHeight > realHeight ? realHeight : maxHeight

                            Behavior on height { UbuntuNumberAnimation{ duration: UbuntuAnimation.SnapDuration } }

                            Component.onCompleted: {
                                var index = redditObj.getSubscribedArray().indexOf(postList.subreddit)
                                if(index !== -1){
                                    positionViewAtIndex(index, ListView.Beginning)
                                } else {
                                    timer.start()
                                }
                            }

                            Timer {
                                id: timer
                                interval: 100
                                onTriggered: {
                                    subredditListView.contentY = -100
                                    subredditListView.returnToBounds()
                                }
                            }

                            header: Column {
                                anchors { left: parent.left; right: parent.right }
                                height: childrenRect.height;
                                //TODO: fix icons
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    height: units.gu(8); width: childrenRect.width
                                    spacing: units.gu(1)
                                    ToolbarButton {
                                        iconSource: "media/noSignal.png"
                                        text: postList.subreddit !== "" ? "Frontpage" : "<b>Frontpage</b>"
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                PopupUtils.close(subredditPopover)
                                                postList.loadSubreddit()
                                            }
                                        }
                                    }
                                    ToolbarButton {
                                        iconSource: "media/ui/comments.svg"
                                        text: postList.subreddit !== "All" ? "All" : "<b>All</b>"
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                PopupUtils.close(subredditPopover)
                                                postList.loadSubreddit("All")
                                            }
                                        }
                                    }
                                    ToolbarButton {
                                        property bool custom: redditObj.getSubscribedArray().indexOf(postList.subreddit) !== -1 || postList.subreddit === "" || postList.subreddit === "All"

                                        iconSource: "media/ui/refresh.svg"
                                        text: custom ? "Custom…" : "<b>Custom…</b>"

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                PopupUtils.close(subredditPopover)
                                                PopupUtils.open(customSubRDialogComponent)
                                            }
                                        }
                                    }
                                    /*ToolbarButton {
                                        iconSource: "media/user.png" //icon could be binoculars
                                        text: "Explore"
                                    }*/
                                }
                                ListItems.ThinDivider {}
                                ListItems.Header {
                                    text: "Subreddits"
                                    enabled: !redditNotifier.subscribedLoading
                                    MouseArea {
                                        enabled: parent.enabled
                                        anchors{
                                            top: parent.top
                                            right: parent.right
                                            bottom: parent.bottom
                                        }
                                        width: units.gu(6)
                                        onClicked: {
                                            var subsrConnObj = redditObj.updateSubscribedArray()
                                        }
                                    }
                                    Image {
                                        source: "media/ui/refresh.svg"
                                        width: units.gu(2.2); height: width
                                        opacity: parent.enabled ? 1 : 0.5
                                        anchors {
                                            top: parent.top
                                            topMargin: units.gu(0.7)
                                            right: parent.right
                                            rightMargin: units.gu(1)
                                        }
                                        sourceSize { width: width; height: height }
                                    }
                                }
                                Item {
                                    anchors { left: parent.left; right: parent.right }
                                    visible: redditNotifier.subscribedLoading
                                    height: visible ? subsrActivityIndicator.height + subsrLabel.height + units.gu(3) : 1
                                    ActivityIndicator {
                                        id: subsrActivityIndicator
                                        running: true
                                        anchors { top: parent.top; topMargin: units.gu(1); horizontalCenter: parent.horizontalCenter }
                                    }
                                    Label {
                                        id: subsrLabel
                                        text: "Loading…"
                                        anchors {
                                            top: subsrActivityIndicator.bottom
                                            topMargin: units.gu(1)
                                            horizontalCenter: parent.horizontalCenter
                                        }
                                    }
                                }
                            }

                            model: subredditSwitcher.model

                            delegate: ListItems.Standard {
                                text: model.name !== postList.subreddit ? model.name : "<b>" + model.name + "</b>"
                                visible: model.name !== ""
                                height: visible ? implicitHeight : 1
                                onClicked: {
                                    PopupUtils.close(subredditPopover)
                                    postList.loadSubreddit(model.name)
                                }
                            }
                        }
                    }
                }

                Component {
                     id: customSubRDialogComponent
                     Dialog {
                         id: customSubRDialog

                         function openSubreddit() {
                             var name = customSubRTextField.text
                             var index = -1
                             var subsrArray = redditObj.getSubscribedArray()
                             for(var i = 0; i < subsrArray.length; i++) {
                                 if(subsrArray[i].toLowerCase() === name.toLowerCase()) {
                                     index = i
                                     break
                                 }
                             }

                             if(index !== -1) {
                                 postList.loadSubreddit(subsrArray[i])
                             } else {
                                 var lowerCaseName = name.toLowerCase()
                                 var firstToUpName = lowerCaseName.substr(0, 1).toUpperCase() + lowerCaseName.substr(1)
                                 postList.loadSubreddit(firstToUpName)
                             }

                             PopupUtils.close(customSubRDialog)
                         }

                         title: "Enter a Custom Subreddit"
                         //text: "Subreddit of the Day:"

                         Component.onCompleted: customSubRTextField.forceActiveFocus()

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
                        callerMargin: units.gu(1.4)
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
                                    text: name !== sortingSwitcher.text ? name : "<b>" + name +"</b>"
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
                        source: "media/ui/user.svg"
                        width: units.gu(4.5); height: units.gu(4.5)
                        anchors.horizontalCenter: parent.horizontalCenter
                        sourceSize { width: width; height: height }
                    }
                    Label {
                        id: userName

                        property string anonString: "[anon]"
                        property string loadingString: "…"

                        readonly property bool isAnon: redditNotifier.activeUser === ""
                        readonly property bool isLoading: redditNotifier.authStatus === "loading"

                        text: !isLoading ? !isAnon ? redditNotifier.activeUser : anonString : loadingString
                        fontSize: "small"
                        anchors {
                            top: userImg.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked:  PopupUtils.open(userPopupComponent, userContainer)
                    }
                    Component {
                        id: userPopupComponent
                        Popover {
                            id: userPopover
                            callerMargin: units.gu(1)
                            Flickable {
                                id: userFlickable
                                anchors { top: parent.top; left: parent.left; right: parent.right }
                                height: Math.min(userColumn.height,  frontPageItem.height - (headerAddition.y + headerAddition.height + units.gu(5)))
                                clip: true
                                contentHeight: userColumn.height
                                UserColumn {
                                    id: userColumn
                                    users: redditObj.getUsers()
                                    selectedIndex: users.indexOf(redditNotifier.activeUser)
                                    loading: redditNotifier.authStatus === 'loading'

                                    onUserDelete: {
                                        PopupUtils.open(userDeleteComponent, false, {user: users[deletedIndex]})
                                        PopupUtils.close(userPopover)
                                    }

                                    onUserSwitch: {
                                        if(redditNotifier.activeUser === users[selectedIndex]) {
                                            //The selected user already is the active user.
                                            PopupUtils.close(userPopover)
                                            return true
                                        }
                                        var postListing = postList //calling postList directly doesn't seem to work
                                        postListing.clearListing()

                                        var switchConnObj = redditObj.switchActiveUser(users[selectedIndex] || "")
                                        switchConnObj.onSuccess.connect(function(){
                                            postListing.loadSubreddit()
                                        })

                                        PopupUtils.close(userPopover)
                                    }

                                    onUserAdd: {
                                        PopupUtils.open(userAddComponent)
                                        PopupUtils.close(userPopover)
                                    }
                                }
                            }
                        }
                    }

                    Component {
                        id: userDeleteComponent
                        Dialog {
                            id: userDeleteDialog

                            property string user

                            title: "Remove User"
                            text: "Are you sure you want to remove user <b>" + user + "</b>?"

                            Item {
                                anchors { left: parent.left; right: parent.right }
                                height: childrenRect.height

                                Button {
                                    text: "Cancel"
                                    gradient: UbuntuColors.greyGradient
                                    onClicked: PopupUtils.close(userDeleteDialog)
                                    anchors.left: parent.left
                                }
                                Button {
                                    text: "Remove"
                                    gradient: UbuntuColors.orangeGradient
                                    anchors.right: parent.right
                                    onClicked: {
                                        var postListing = postList

                                        var isActiveUser = redditObj.deleteUser(userDeleteDialog.user)
                                        if (isActiveUser) {
                                            postListing.clearListing()
                                            var logoutConnObj = redditObj.logout()
                                            logoutConnObj.onSuccess.connect(function(){
                                                postListing.loadSubreddit()
                                            })
                                        }

                                        PopupUtils.close(userDeleteDialog)
                                    }
                                }
                            }
                        }
                    }

                    Component {
                         id: userAddComponent
                         Dialog {
                             id: userAddDialog

                             property string defaultText: "The Frontpage of the Internet"

                             function startLogin() {
                                 if (usernameTextField.text == "" || passwordTextField.text == "") return true;
                                 usernameTextField.focus = false
                                 passwordTextField.focus = false

                                 var loginConnObj = redditObj.loginNewUser(usernameTextField.text, passwordTextField.text)
                                 loginConnObj.onSuccess.connect(function(){
                                     redditObj.updateSubscribedArray()
                                     postList.loadSubreddit()
                                     PopupUtils.close(userAddDialog)
                                 })
                                 loginConnObj.onError.connect(function(errorMessage){
                                     passwordTextField.text = ""
                                     userAddDialog.text = "<font color='red'>" + errorMessage + "</font>"
                                 })
                             }

                             title: "Log in to Reddit"
                             text: "The Frontpage of the Internet"

                             Component.onCompleted: usernameTextField.forceActiveFocus()

                             TextField {
                                 id: usernameTextField
                                 placeholderText: 'Username'
                                 hasClearButton: true
                                 onAccepted: passwordTextField.forceActiveFocus()
                                 onTextChanged: userAddDialog.text = userAddDialog.defaultText
                             }
                             TextField {
                                 id: passwordTextField
                                 placeholderText: 'Password'
                                 hasClearButton: true
                                 echoMode: TextInput.Password
                                 onAccepted: userAddDialog.startLogin()
                                 onTextChanged: userAddDialog.text = userAddDialog.defaultText
                             }

                             Item {
                                 anchors { left: parent.left; right: parent.right }
                                 height: childrenRect.height
                                 Button {
                                     text: "Cancel"
                                     gradient: UbuntuColors.greyGradient
                                     onClicked: PopupUtils.close(userAddDialog)
                                     anchors.left: parent.left
                                 }
                                 ActivityIndicator {
                                     id: loginIndicator
                                     anchors{
                                         right: loginButton.left
                                         rightMargin: units.gu(1)
                                         verticalCenter: loginButton.verticalCenter
                                     }
                                     running: redditNotifier.authStatus === "loading"
                                 }

                                 Button {
                                     id: loginButton
                                     text: "Login"
                                     gradient: UbuntuColors.orangeGradient
                                     onClicked: userAddDialog.startLogin()
                                     anchors.right: parent.right
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
        running: postList.loading || redditNotifier.authStatus === 'loading'
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
            source: "media/ui/spinner.png"
            width: units.gu(3); height: units.gu(3)
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
