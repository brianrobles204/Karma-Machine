.pragma library

/*
    #Known Bugs/Limitations
        *Showdown.js ignores '\' as a way to cancel markdown. Not even extensions can override this
        *TODO: Links formatted with a space like [this] (http://www.website.com) are not recognized
*/

function getExtensionsObj(color, gridUnits) {

    //Superscript Extension ('^' in Reddit Markdown)
    //Designed to have nested superscripts if needed
    var supExt = function(converter) {
        return [
                    {
                        type:"lang",
                        filter: function(text) {
                            var supRegex = /(\\)?\^([\S]+)\b/gi
                            function supOutput(match, escape, text) {
                                return escape === "\\" ? "^ " + text : "<sup>" + text + " </sup>"
                            }

                            do {
                                text = text.replace(supRegex, supOutput)
                            } while(text.match(supRegex))

                            return text
                        }
                    }
                ]
    }


    //Quotes Extension ('>' in markdown). Makes quotes readable and aesthetic in QML Rich Text
    //Large hack because QML Rich Text does not recognize background colors for individual table cells, nor background images at all it seems. Can't seem to set height either.
    //Solved by creating a table with our quoteBarColor background, then creating a table inside the table with our text and the normal background.
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


    //Link Extension
    var linkExt = function (converter) {
        var linkColor = "#cb7f00" //orange

        //Gets replaced (i.e. autolinked) text, given regex, but ignores pre-formatted links like [this](http://example.com)
        function getReplacedText(text, regex, output) {
            //Exclude links which are already formated for text. Taken from Showdown.js
            var formattedLinks = text.match(/(\[((?:\[[^\]]*\]|[^\[\]])*)\]\([ \t]*()<?(.*?(?:\(.*?\).*?)?)>?[ \t]*((['"])(.*?)\6[ \t]*)?\))/g)

            var newText = ""
            if (formattedLinks) {
                //There exists some formatted links, so we split the whole string along these formatted links, and replace these split strings, one at a time
                var curTextSlice = ""
                for (var i = 0; i < formattedLinks.length; i++) {
                    var textSlice = text.slice(curTextSlice.length, text.indexOf(formattedLinks[i], curTextSlice.length))
                    curTextSlice += textSlice + formattedLinks[i]
                    var replacedSlice = textSlice.replace(regex, output) //autolink the current slice
                    newText += replacedSlice + formattedLinks[i]
                }
                newText += text.slice(curTextSlice.length, -1).replace(regex, output) //add the remaining text, now autolinked
            } else {
                //No match for any formatted links, so just replace the whole thing
                newText = text.replace(regex, output)
            }

            return newText
        }

        return [
                    {
                        //Arbitrary Autolink Extension. Allows arbitrary URLs to be linked automatically
                        type: 'lang',
                        filter: function (text) {
                            var autoLinkRegex = /\b((?:[a-z][\w-]+:(?:\/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))\b/gi
                            var autoLinkOutput = '[$1]($1)'
                            return getReplacedText(text, autoLinkRegex, autoLinkOutput)
                        }
                    },{
                        //Subreddit Autolink Extension. Allows subreddits formatted as '/r/subreddit' to be linked automatically
                        type: 'lang',
                        filter: function (text) {
                            var subRLinkRegex = /(\/r\/[\S]+)\b/gi
                            var subRLinkOutput = '[$1](http://www.reddit.com$1)'
                            return getReplacedText(text, subRLinkRegex, subRLinkOutput)
                        }
                    },
                    {
                        //Link Color Extension. Changes all links' color into one of your choosing
                        type: 'output',
                        regex: '<a href="(.*?)">',
                        replace: function (match, link) {
                            return '<a href="' + link + '" style="color:' + linkColor + '">'
                        }
                    }
                ]
    }


    return {
        extensions: [supExt, quoteExt, linkExt]
    }
}
