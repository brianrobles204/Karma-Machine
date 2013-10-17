.pragma library

function getExtensionsObj(color, gridUnits) {

    //Quotes modification ('>' in markdown) so that it becomes readable and aesthetic in QML Rich Text
    //Large hack because QML Rich Text does not recognize background colors for individual table cells, nor background images at all it seems. You can't seem to set heights too.
    //Solved by creating a table with our quoteBarColor background, then creating a table inside with our text and the normal background.
    var quoteExt = function(converter) {
        var quoteBarColor = "#999999"
        var quoteBarWidth = gridUnits*0.15

        var topMargin = gridUnits*0.5
        var leftMargin = gridUnits*1

        var _quoteBarWidthOffset = quoteBarWidth + 2 //to offset the negative cellpadding

        return [
                    { type: 'output', regex: '<blockquote>', replace: '<p style="font-size:' + topMargin + 'px">&nbsp;</p><table cellpadding="-2" style="margin-left:' + _quoteBarWidthOffset + 'px;background-color:' + quoteBarColor + '"><tr><td><table style="background-color:' + color + '"><tr><td style="padding-left:' + leftMargin + 'px">' },
                    { type: 'output', regex: '</blockquote>', replace: '</td></tr></table></td></tr></table>' }
                ]
    }


    //Link modification to make them color orange
    var linkExt = function (converter) {
        var linkColor = "#cb7f00"

        function outputReplace(match) {
            return "hamster"
        }

        return [
                    {
                        type: 'lang',
                        filter: function (text) {
                            var match = text.match(/(\[((?:\[[^\]]*\]|[^\[\]])*)\]\([ \t]*()<?(.*?(?:\(.*?\).*?)?)>?[ \t]*((['"])(.*?)\6[ \t]*)?\))/g)
                            for (var i = 0; i < match.length; i++) {
                                var textSlice = text.slice(0,text.indexOf(match[i]))
                                var replacedSplit = textSlice.replace(/\b((?:[a-z][\w-]+:(?:\/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))\b/gi,outputReplace);
                                text = replacedSplit + text.slice(text.indexOf(match[i],-1))
                            }
                            return text
                        }
                    },
                    {
                        type: 'output',
                        regex: '<a href="(.*)">',
                        replace: function (match, link) {
                            return '<a href="' + link + '" style="color:' + linkColor + '">'
                        }
                    }
                ]
    }


    return {
        extensions: [quoteExt, linkExt]
    }
}
