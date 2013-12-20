Qt.include("Showdown.js")
Qt.include("Extensions.js")

function timeSince(date) {
    //Thanks to stackoverflow.com/questions/3177836
    var seconds = Math.floor((new Date() - date) / 1000);
    var interval = Math.floor(seconds / 31536000);

    function fixPlural(name, interval) {
        if(interval === 1) {
            return name.slice(0, - 1);
        }
        return name;
    }

    if (interval >= 1) {
        return interval + fixPlural(" years", interval);
    }
    interval = Math.floor(seconds / 2592000);
    if (interval >= 1) {
        return interval + fixPlural(" months", interval);
    }
    interval = Math.floor(seconds / 86400);
    if (interval >= 1) {
        return interval + fixPlural(" days", interval);
    }
    interval = Math.floor(seconds / 3600);
    if (interval >= 1) {
        return interval + fixPlural(" hours", interval);
    }
    interval = Math.floor(seconds / 60);
    if (interval >= 1) {
        return interval + fixPlural(" minutes", interval);
    }
    return Math.floor(seconds) + fixPlural(" seconds", interval);
}

function commentsSimple(num_comments) {
    if(Math.floor(num_comments/1000) > 0) {
        return Math.floor(num_comments/1000) + "k"
    } else {
        return num_comments
    }
}

function clamp(x, min, max) {
    if (min <= max) {
        return Math.max(min, Math.min(x, max));
    } else {
        // swap min/max if min > max
        return clamp(x, max, min);
    }
}

function simpleFixHtmlChars(text) {
    text = text.replace(/&#0*39;/g, "'");
    text = text.replace(/&quot;/g, '"');
    text = text.replace(/&amp;/g, '&');
    return text
}


function getHtmlText(text, color) {
    var encodedText = simpleFixHtmlChars(text)
    var extensionsObj = getExtensionsObj(color)

    var converter = new Showdown.converter(extensionsObj)
    return converter.makeHtml(encodedText)
}
