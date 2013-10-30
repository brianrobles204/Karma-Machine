//
// Extensions.js -- Extensions for showdown.js in order to render Reddit Markdown well in QML Rich Text
//
// Known Bugs/Limitations
//  *Showdown.js ignores '\' as a way to cancel markdown. Seems that even extensions cannot override this.
//  *Designed for QML Rich Text, not Html. If you're gonna show Reddit Markdown in a browser,
//    consider using Snuownd.js instead (https://github.com/gamefreak/snuownd)
//    TODO: Look into Snuownd.js as an alternative to Showdown.js.
//      It needs to be extensible, and within reasonable performance costs. Unfortunately it's not well documented.
//  *TODO: Links formatted with a space like [this]_(http://www.website.com) are not recognized
//  *Autolink extension thinks that css rules (e.g. 'timing:ease-out') are URLs.
//    Bad for /r/web_design and similar sites.
//    TODO: Make Autolink ignore text inside <code> tags
//


//bgColor is simply the background color behind the text, because Markdown Quotes render without a transparent background
//TODO: remove dependency for bgColor, by calling a different function that replaces a placeholder with our needed color
function getExtensionsObj(bgColor) {
    //To preserve resolution independence. 8[px] on most desktop screens.
    //Requires the Ubuntu SDK. Replace when porting
    var gridComponent = Qt.createQmlObject("import QtQuick 2.0; import Ubuntu.Components 0.1; Item{ height: units.gu(1)}", Qt.application)
    var gridUnits = gridComponent.height
    gridComponent.destroy()

    //Superscript Extension ('^' in Reddit Markdown)
    //Designed to have nested superscripts if needed
    //Although QML Rich Text doesn't seem to render nested superscripts anyway
    var supExt = function(converter) {
        return [
                    {
                        type:"lang",
                        filter: function(text) {
                            var supRegex = /(\\)?\^([\S]+)/gi
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


    //Strikethrough Extension ('~~text~~' in Markdown).
    var strikethroughExt = function(converter) {
        //Type must be 'output' instead of 'lang' because Showdown.js manipulates the tilde character
        return [{ type: 'output', regex: '~~((?!\s).+?(?!\s))~~', replace: '<s>$1</s>' }]
    }


    //Quotes Extension ('>' in Markdown).
    var quoteExt = function(converter) {
        var quoteBarColor = "#999999"
        var quoteBarWidth = gridUnits*0.15

        var topMargin = gridUnits*0.5
        var leftMargin = gridUnits*1

        var _quoteBarWidthOffset = quoteBarWidth + 2 //to offset the negative cellpadding

        return [
                    {
                        //Fix Quote Extension.
                        //Reddit sends Markdown with HTML safe entities,
                        // instead of converting all &lt; and &gt; to '<' and '>' respectively, which QML may misinterpret as tags,
                        // we only convert them when they're to be used in Markdown, such as in blockquotes.
                        type: 'lang',
                        filter: function(text) {
                            return text.replace(/((^[ \t]*(?:&gt;)[ \t]?.+\n(.+\n)*\n*)+)/gm,
                                                function(match, m1){
                                                    var gtRegex = /^[ \t]*(>)*(?:&gt;)[ \t]?/gm

                                                    //Individually replace all &gt; at the start of the string to '>'
                                                    do {
                                                        match = match.replace(gtRegex, "$1>")
                                                    } while(match.match(gtRegex))

                                                    return match
                                                })
                        }
                    },
                    //QML Quotes Extension.  Makes quotes readable and aesthetic in QML Rich Text
                    //Large hack because QML Rich Text does not recognize background colors for individual table cells,
                    //  nor background images at all it seems. Can't seem to set height either.
                    //Solved by creating a table with our quoteBarColor background, then creating a table inside the table with our text and the normal background.
                    { type: 'output', regex: '<blockquote>', replace: '<p style="font-size:' + topMargin + 'px">&nbsp;</p><table cellpadding="-2" style="margin-left:' + _quoteBarWidthOffset + 'px;background-color:' + quoteBarColor + '"><tr><td><table style="background-color:' + bgColor + '"><tr><td style="padding-left:' + leftMargin + 'px">' },
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
                    newText += textSlice.replace(regex, output) + formattedLinks[i]
                    curTextSlice += textSlice + formattedLinks[i]
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
                            //Thanks to John Gruber. Taken from http://daringfireball.net/2010/07/improved_regex_for_matching_urls
                            var autoLinkRegex = /\b((?:[a-z][\w-]+:(?:\/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))\b/gi
                            var autoLinkOutput = '[$1]($1)'
                            return getReplacedText(text, autoLinkRegex, autoLinkOutput)
                        }
                    },{
                        //Subreddit/User Autolink Extension. Allows text formatted as '/r/subreddit' or '/u/user' to be linked automatically
                        type: 'lang',
                        filter: function (text) {
                            var subRLinkRegex = /(\/[ru]\/(?:\S)+?)\b(?!\+|[\w])/gi
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


    //Fix Italics in Url Extension. Showdown converts the text between underscores in URLs into italicized text; this fixes that behavior.
    var fixItalicsinUrlExt = function(converter) {
        return [
                    {
                        type: 'output',
                        regex: '<a href="(.*?)">(.*?)<\/a>',
                        replace: function (match, tags, link) {
                            var fixedLink = link.replace(/<em>(.+?)<\/em>/g,"_$1_")
                            return '<a href="'+ tags + '">' + fixedLink + "</a>"
                        }
                    }
                ]
    }


    //Fix Entities in Code Extension.
    //Showdown.js converts all entities in <code> tags to HTML safe characters (e.g. & -> &amp;)
    //  but the Markdown that Reddit sends is already HTML safe, so text is encoded as HTML safe twice!
    //This extension undoes one level of HTML safety encoding.
    //Note: Since the Markdown sent is already HTML safe, we only to decode &amp;
    var fixEntitiesInCodeExt = function(converter) {
        return [
                    {
                        type: 'output',
                        filter: function(text) {
                            return text.replace(/<code>([\s\S]*)<\/code>/gm, function(match, text) {
                                return match.replace(/&amp;/g,"&")
                            })
                        }
                    }
                ]
    }


    return {
        extensions: [supExt, strikethroughExt, quoteExt, linkExt, fixItalicsinUrlExt, fixEntitiesInCodeExt]
    }
}
