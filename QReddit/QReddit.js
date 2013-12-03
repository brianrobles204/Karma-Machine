.import QtQuick.LocalStorage 2.0 as LocalStorage
Qt.include('QRObjects.js');

var QReddit = function(userAgent, applicationName) {

    BaseReddit.apply(this, arguments);

    this.notifier = createObject("NotifierObject.qml");


    var _userHandler = (function(root) {
        //extends QReddit with user handling methods from within an anonymous function

        //avoid directly manipulating variable activeuser
        var activeUser = "";

        function getDatabase() {
            return LocalStorage.LocalStorage.openDatabaseSync(applicationName, "1.0", "User Storage Database", 1000000);
        }

        function getDatabaseTransaction(statement, values) {
            var database = getDatabase();
            var response;
            database.transaction(function(transaction) {
                response = values ? transaction.executeSql(statement, values) : transaction.executeSql(statement);
            });
            return response;
        }

        root._addUser = function(username, passwd) {
            var subscribed = "";
            var dbTransaction = getDatabaseTransaction('INSERT OR REPLACE INTO RedditUsers VALUES (?,?,?);',
                                                       [username, passwd, subscribed]);
            if (dbTransaction.rowsAffected > 0) {
                console.log("Log: Added user \"" + username + "\"");
            } else {
                throw "Error: _addUser(): Transaction failed.";
            }
        }

        root._removeUser = function(username) {
            //Check if username is stored in database
            if(!root._isUserStored(username)) {
                throw "Error: _removeUser(): Username \"" + username + "\" is not stored in table.";
            }
            //Check if username given is the active user
            if(username === activeUser) {
                throw "Error: _removeUser(): Username \"" + username + "\" is the active user.";
            }

            var dbTransaction = getDatabaseTransaction('DELETE FROM RedditUsers WHERE username IN (?);', username);
            if (dbTransaction.rowsAffected > 0){
                console.log("Log: Removed user \"" + username + "\"");
            } else {
                throw "Error: _removeUser(): Transaction failed.";
            }
        }

        root._getUser = function(username) {
            //Check if username is stored in database
            if(!root._isUserStored(username)) {
                throw "Error: _getUser(): Username \"" + username + "\" is not stored in table.";
            }

            var userObj = {
                user: username,
                passwd: ''
            }

            try {
                var dbTransaction = getDatabaseTransaction('SELECT passwd FROM RedditUsers WHERE username=?;', [username]);
                if(dbTransaction.rows.length > 0) {
                    userObj.passwd = dbTransaction.rows.item(0).passwd;
                } else {
                    throw "Transaction failed."
                }
            } catch (error) {
                console.error("Error: _getUser(): \"" + error + "\"");
            }

            return userObj;
        }

        root._getActiveUserFromDB = function() {
            //Do not use this function. Use getActiveUser(). This function is for initialization purposes only.
            var activeUser = "";
            try {
                var dbTransaction = getDatabaseTransaction('SELECT username FROM ActiveRedditUser LIMIT 1 OFFSET 0');
                if(dbTransaction.rows.item(0)) {
                    activeUser = dbTransaction.rows.item(0).username
                }
            } catch (error) {
                console.error("Error: _getActiveUserFromDB(): \"" + error + "\"");
            }

            return activeUser;
        }

        function checkLoginError(response) {
            if (response.json.data === undefined) throw response.json.errors[0][1];
        }

        root._loginUser = function(username, passwd, callback) {
            var loginConnObj;
            root.notifier.authStatus = 'loading';

            if (username !== root.notifier.currentAuthUser && root.notifier.currentAuthUser !== "") {
                //A different user is already logged in. We must log out first.

                //Since we're calling getAPIConnection() inside a function, we can't return the Connection object it gives.
                //Instead we mirror its responses with a dummy Connection object.
                loginConnObj = createObject("ConnectionObject.qml");

                var logoutConnObj = root.logout(true);
                logoutConnObj.onSuccess.connect(function(){
                    var apiLoginConnObj = root.getAPIConnection('login', {
                                                                    user: username,
                                                                    passwd: passwd
                                                                });
                    apiLoginConnObj.onConnectionSuccess.connect(loginConnObj.connectionSuccess);
                    apiLoginConnObj.onSuccess.connect(loginConnObj.success);
                    apiLoginConnObj.onRaiseRetry.connect(loginConnObj.raiseRetry);
                    apiLoginConnObj.onError.connect(loginConnObj.error);
                });
            } else {
                //No one is logged in.
                loginConnObj = root.getAPIConnection('login', {
                                                         user: username,
                                                         passwd: passwd
                                                     });
            }

            loginConnObj.onConnectionSuccess.connect(function (response){
                try {
                    checkLoginError(response);
                    if(callback !== undefined) callback();
                } catch (error) {
                    loginConnObj.error(error);
                    return false;
                }
                loginConnObj.response = response.json.data;
                loginConnObj.success();
            });
            loginConnObj.onSuccess.connect(function() {
                root.modhash = loginConnObj.response.modhash;
                console.log("Log: Logged in \"" + username + "\" successfully.");
                root.notifier.authStatus = 'done';
                root.notifier.currentAuthUser = username;
            });
            loginConnObj.onError.connect(function (response) {
                root.notifier.authStatus = 'error';
            });

            return loginConnObj;
        }

        root._isUserStored = function(username) {
            var storedUsers = root.getUsers();
            return (storedUsers.indexOf(username) !== -1 || username === "");
        }

        root._setActiveUser = function(username) {
            //Check if username is stored in database
            if(!root._isUserStored(username) && username !== "") {
                throw "Error: _setActiveUser(): Username \"" + username + "\" is not stored in table.";
            }
            var dbTransaction = getDatabaseTransaction('UPDATE ActiveRedditUser SET username=?;', [username]);
            if (dbTransaction.rowsAffected > 0){
                console.log("Log: Set \"" + username + "\" as the active user")
                activeUser = username
                root.notifier.activeUser = activeUser;
            } else {
                throw "Error: _setActiveUser(): Transaction failed."
            }
        }

        root.getUsers = function() {
            //Returns an array of usernames stored in the `users` table.
            var users = [];
            try {
                var dbTransaction = getDatabaseTransaction('SELECT username FROM RedditUsers;');
                for (var i = 0; i < dbTransaction.rows.length; i++) {
                    var username = dbTransaction.rows.item(i).username
                    if (username !== "") users.push(username);
                }
            } catch (error) {
                console.error("Error: getUsers(): \"" + error + "\" Returning empty array.")
            }
            return users;
        }

        root.getActiveUser = function() {
            return activeUser || "";
        }


        root.updateSubscribedArray = function() {
            //Returns a Connection QML object. Updates the activeUser's subscribed subreddits from the internet.
            var username = root.getActiveUser();
            var isAUser = username !== "";
            var subsrConnObj;

            function parseListing(listing) {
                var subsrArray = [];
                for (var i = 0; i < listing.length; i++) {
                    var subsrName = listing[i].data.display_name;
                    subsrName = subsrName.charAt(0).toUpperCase() + subsrName.slice(1)//.toLowerCase();
                    subsrArray.push(subsrName);
                }
                return subsrArray;
            }

            function updateMoreSubscribed(after) {
                var subsrConnObj = root.getAPIConnection("subreddits_mine subscriber", {
                                                             after: after,
                                                             limit: 100
                                                         });
                subsrConnObj.onConnectionSuccess.connect(function(response){
                    var subsrArray = parseListing(response.data.children);
                    if(typeof response.data.after === "string") {
                        var updConnObj = updateMoreSubscribed(response.data.after);
                        updConnObj.onSuccess.connect(function(){
                            subsrArray = subsrArray.concat(updConnObj.response);
                            subsrConnObj.response = subsrArray;
                            subsrConnObj.success();
                        });
                    } else {
                        subsrConnObj.response = subsrArray;
                        subsrConnObj.success();
                    }
                });
                return subsrConnObj;
            }

            if (isAUser) {
                subsrConnObj = root.getAPIConnection("subreddits_mine subscriber", {limit: 100});
            } else {
                subsrConnObj = root.getAPIConnection("subreddits_default");
            }

            subsrConnObj.onConnectionSuccess.connect(function(response){
                var subsrArray = parseListing(response.data.children);

                if(typeof response.data.after === "string" && isAUser) {
                    var updConnObj = updateMoreSubscribed(response.data.after);
                    updConnObj.onSuccess.connect(function(){
                        subsrArray = subsrArray.concat(updConnObj.response);
                        subsrArray = subsrArray.sort();
                        subsrConnObj.response = subsrArray.join();
                        subsrConnObj.success();
                    });
                } else {
                    subsrArray = subsrArray.sort();
                    subsrConnObj.response = subsrArray.join();
                    subsrConnObj.success();
                }
            });
            subsrConnObj.onSuccess.connect(function(){
                var dbTransaction = getDatabaseTransaction('UPDATE RedditUsers SET subscribed=? WHERE username=?;',
                                                           [subsrConnObj.response, username]);
                if (dbTransaction.rowsAffected > 0){
                    console.log("Log: Set updated subreddit list for \"" + username + "\"");
                } else {
                    throw "Error: _setActiveUser(): Transaction failed.";
                }
            });

            return subsrConnObj;
        }

        root.getSubscribedArray = function(username) {
            //Returns a stored user's subscribed subreddits.
            //If username is not passed, the activeUser's subreddits will be returned.
            var subscribed;
            username = username || root.getActiveUser();

            //Check if username is stored in database
            if(!root._isUserStored(username)) {
                username = root.getActiveUser();
            }

            try {
                var dbTransaction = getDatabaseTransaction('SELECT subscribed FROM RedditUsers WHERE username=?;', [username]);
                if(dbTransaction.rows.length > 0) {
                    subscribed = dbTransaction.rows.item(0).subscribed;
                } else {
                    throw "Transaction failed.";
                }
            } catch (error) {
                subscribed = "";
            }

            return subscribed.split(',');
        }


        var initializeDatabase = (function() {
            try {
                //Create tables RedditUsers and ActiveRedditUser.
                getDatabaseTransaction('CREATE TABLE IF NOT EXISTS RedditUsers(username TEXT UNIQUE, passwd TEXT, subscribed TEXT);');
                getDatabaseTransaction('CREATE TABLE IF NOT EXISTS ActiveRedditUser(username TEXT UNIQUE);');
                getDatabaseTransaction('INSERT INTO ActiveRedditUser SELECT "" WHERE NOT EXISTS (SELECT * FROM ActiveRedditUser LIMIT 1)');
                getDatabaseTransaction('INSERT INTO RedditUsers(username, passwd, subscribed) SELECT "", "", "" WHERE NOT EXISTS (SELECT * FROM RedditUsers LIMIT 1)');
                //Set the active user
                activeUser = root._getActiveUserFromDB();
                root.notifier.activeUser = activeUser;
            } catch (error) {
                throw "Error: QReddit initializeDatabase: \"" + error + "\""
            }
            console.log("Log: QReddit has been initialized")
        }());

    }(this));

    this.loginNewUser = function(username, password) {
        //Returns a Connection QML object. Authenticates a new user.
        //  If successful, stores the new user to the `RedditUsers` table and sets it as the active user.
        var root = this;
        var loginConnObj = this._loginUser(username, password, function() {
            root._addUser(username, password);
            root._setActiveUser(username);
        });
        return loginConnObj;
    }

    this.loginActiveUser = function() {
        //Returns a Connection QML object. Logs in the currently active user.
        //TODO: refactor code into one try-catch statement, one if the activeUser is stored/anonymous and one if not

        var username = this.getActiveUser();
        var password = "";

        if (username !== "") {
            try {
                password = this._getUser(username).passwd;
            } catch (error) {
                password = "";
            }
            var loginConnObj =  this._loginUser(username, password);

            //If the activeUser is not actually stored, or the stored password is blank, raise an error
            if (password === "") {
                var loginTimer = createTimer(1);
                loginTimer.onTriggered.connect(function() {
                    loginTimer.destroy();
                    loginConnObj.error("Password error.");
                });
            }

            return loginConnObj;
        }

        var noLoginConnObj = createObject("ConnectionObject.qml");
        console.log("Log: No user is logged in.");
        this.notifier.authStatus = 'none';

        var noLoginTimer = createTimer(1);
        noLoginTimer.onTriggered.connect(function() {
            noLoginTimer.destroy();
            noLoginConnObj.success();
        });

        return noLoginConnObj;
    }

    this.switchActiveUser = function(username) {
        //Returns a Connection QML object. Logs a stored user into Reddit and sets it as the active user if successful.
        if (username === this.getActiveUser()) return; //Do nothing if the user given is already the active user

        if(username === "") {
            //Simply logout
            var outConnObj = this.logout();
            return outConnObj;
        }

        var password = "",
            userError = "",
            root = this;

        try {
            password = this._getUser(username).passwd;
        } catch (error) {
            //TODO: return dummy connection object with error
            userError = error;
        }

        var loginConnObj = root._loginUser(username, password, function() {
            root._setActiveUser(username);
        });

        return loginConnObj;
    }

    this.logout = function(loadingAuth) {
        //Returns a Connection QML object. Logs the app out of Reddit.
        //Passing true to logout() will stop the Connection object from changing the notifier's authStatus when successful.
        //* Reddit's logout api returns a 404, despite it working fine. Do not connect to onError as it is unreliable.
        this.notifier.authStatus = 'loading';

        var logoutConnObj = this.getAPIConnection('logout');
        var root = this;
        logoutConnObj.onError.connect(function(error){
            logoutConnObj.success();
        });
        logoutConnObj.onSuccess.connect(function(){
            if(!loadingAuth) root.notifier.authStatus = 'none';
            root.notifier.currentAuthUser = "";
            root._setActiveUser("");
        });

        return logoutConnObj;
    }

    this.deleteUser = function(username) {
        //Returns true if the given user to be deleted is the activeUser. Removes a user from the `RedditUsers` table.
        var isActiveUser = username === this.getActiveUser();
        if (isActiveUser) this._setActiveUser("");
        this._removeUser(username);
        return isActiveUser;
    }


    this.getSubredditObj = function(srName) {
        //Returns a Subreddit Object. If srName is omitted, the Subreddit Object will correspond to the Reddit Frontpage.
        return srName ? new SubredditObj(this, srName) : new SubredditObj(this);
    }

    this.getUserObj = function(username) {
        //Returns a User Object.
        return new UserObj(this, username || "");
    }
}
