.pragma library

function getExtensionsObj(color, gridUnits) {

    var quoteExt = function(converter) {
        return [
            { type: 'output', regex: '<blockquote>', replace: '<p style="font-size:' + gridUnits*0.5 + 'px">.</p><table cellpadding="-2" style="background-color:#999999"><tr><td> </td><td><table style="background-color:' + color + '"><tr><td style="padding-left:' + gridUnits*1 + 'px">' },
            { type: 'output', regex: '</blockquote>', replace: '</td></tr></table></td></tr></table>' }
        ];
      }

    return {
        extensions: [quoteExt]
    }
}
