function timeSince(date) {
    //Thanks to stackoverflow.com/questions/3177836
    var seconds = Math.floor((new Date() - date) / 1000);
    var interval = Math.floor(seconds / 31536000);

    if (interval > 1) {
        return interval + " years";
    }
    interval = Math.floor(seconds / 2592000);
    if (interval > 1) {
        return interval + " months";
    }
    interval = Math.floor(seconds / 86400);
    if (interval > 1) {
        return interval + " days";
    }
    interval = Math.floor(seconds / 3600);
    if (interval > 1) {
        return interval + " hours";
    }
    interval = Math.floor(seconds / 60);
    if (interval > 1) {
        return interval + " minutes";
    }
    return Math.floor(seconds) + " seconds";
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

function htmlspecialchars_decode (string, quote_style) {
  // http://kevin.vanzonneveld.net
  // + original by: Mirek Slugen
  // + improved by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
  // + bugfixed by: Mateusz "loonquawl" Zalega
  // + input by: ReverseSyntax
  // + input by: Slawomir Kaniecki
  // + input by: Scott Cariss
  // + input by: Francois
  // + bugfixed by: Onno Marsman
  // + revised by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
  // + bugfixed by: Brett Zamir (http://brett-zamir.me)
  // + input by: Ratheous
  // + input by: Mailfaker (http://www.weedem.fr/)
  // + reimplemented by: Brett Zamir (http://brett-zamir.me)
  // + bugfixed by: Brett Zamir (http://brett-zamir.me)
  // * example 1: htmlspecialchars_decode("<p>this -&gt; &quot;</p>", 'ENT_NOQUOTES');
  // * returns 1: '<p>this -> &quot;</p>'
  // * example 2: htmlspecialchars_decode("&amp;quot;");
  // * returns 2: '&quot;'
  var optTemp = 0,
    i = 0,
    noquotes = false;
  if (typeof quote_style === 'undefined') {
    quote_style = 2;
  }
  string = string.toString().replace(/&lt;/g, '<').replace(/&gt;/g, '>');
  var OPTS = {
    'ENT_NOQUOTES': 0,
    'ENT_HTML_QUOTE_SINGLE': 1,
    'ENT_HTML_QUOTE_DOUBLE': 2,
    'ENT_COMPAT': 2,
    'ENT_QUOTES': 3,
    'ENT_IGNORE': 4
  };
  if (quote_style === 0) {
    noquotes = true;
  }
  if (typeof quote_style !== 'number') { // Allow for a single string or an array of string flags
    quote_style = [].concat(quote_style);
    for (i = 0; i < quote_style.length; i++) {
      // Resolve string input to bitwise e.g. 'PATHINFO_EXTENSION' becomes 4
      if (OPTS[quote_style[i]] === 0) {
        noquotes = true;
      } else if (OPTS[quote_style[i]]) {
        optTemp = optTemp | OPTS[quote_style[i]];
      }
    }
    quote_style = optTemp;
  }
  if (quote_style & OPTS.ENT_HTML_QUOTE_SINGLE) {
    string = string.replace(/&#0*39;/g, "'"); // PHP doesn't currently escape if more than one 0, but it should
    // string = string.replace(/&apos;|&#x0*27;/g, "'"); // This would also be useful here, but not a part of PHP
  }
  if (!noquotes) {
    string = string.replace(/&quot;/g, '"');
  }
  // Put this in last place to avoid escape being double-decoded
  string = string.replace(/&amp;/g, '&');

  return string;
}
