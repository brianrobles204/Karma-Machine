.pragma library
//Known bugs/limitations: Showdown.js ignores '\' as a way to cancel markdown. Not even extensions can override this

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

    //Quotes Extension ('>' in markdown) so that it becomes readable and aesthetic in QML Rich Text
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

        return [
                    {
                        //Autolink Extension that allows arbitrary URLs to be formatted automatically
                        type: 'lang',
                        filter: function (text) {
                            //Exclude links which are already formated for text, e.g. [like](http://www.this.com)
                            var formattedLinks = text.match(/(\[((?:\[[^\]]*\]|[^\[\]])*)\]\([ \t]*()<?(.*?(?:\(.*?\).*?)?)>?[ \t]*((['"])(.*?)\6[ \t]*)?\))/g)

                            //Thanks to John Gruber, http://daringfireball.net/2010/07/improved_regex_for_matching_urls
                            var linkRegex = /\b((?:[a-z][\w-]+:(?:\/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))\b/gi
                            var linkOutput = '<a href="$1">$1</a>'

                            var newText = ""
                            if (formattedLinks) {
                                //There exists some formatted links, so we split the whole string along these formatted links, and autolink these split strings one at a time
                                var curTextSlice = ""
                                for (var i = 0; i < formattedLinks.length; i++) {
                                    var textSlice;
                                    /*if (i == 0) {
                                        //still the first formatted link, start from zero
                                        textSlice = text.slice(0,text.indexOf(formattedLinks[i]))
                                    } else {
                                        //after the first formatted link, start from the end of the last match
                                        textSlice = text.slice(curTextSlice.length, text.indexOf(formattedLinks[i], curTextSlice.length))
                                    }*/
                                    textSlice = text.slice(curTextSlice.length, text.indexOf(formattedLinks[i], curTextSlice.length))
                                    curTextSlice += textSlice + formattedLinks[i]
                                    var replacedSlice = textSlice.replace(linkRegex, linkOutput) //autolink the current slice
                                    newText += replacedSlice + formattedLinks[i]
                                }
                                newText += text.slice(newText.length, -1).replace(linkRegex, linkOutput) //add the remaining text, now autolinked
                            } else {
                                //No match for any formatted links, so just autolink the whole thing
                                newText = text.replace(linkRegex, linkOutput)
                            }

                            return newText
                        }
                    },
                    {
                        //Link Color Extension that changes all links' color into one of your choosing
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
