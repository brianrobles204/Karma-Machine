.pragma library

//TODO: change method of adding listElements from string manipulation to listModel function calls.
function arrayToListModel(array) {
    var listStr = "import QtQuick 2.0; ListModel { "
    for (var i = 0; i < array.length; i++) {
        listStr += "ListElement  { name: '" + array[i] + "' } ";
    }
    listStr += "}"
    var listModel = Qt.createQmlObject(listStr, Qt.application);
    return listModel;
}
