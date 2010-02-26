function stringOrHref(s) {
  if (typeof(s) == 'string')
    return s;
  else {
    return s.href;
  }
}

function runScripts(e) {
  if (e.nodeType != 1) return;

  if (e.tagName.toLowerCase() == 'script') {
    eval(e.text);
  }
  else {
    for(var i = 0; i < e.children.length; ++i) {
      runScripts(e.children[i]);
    }
  }
}

function jsget(elem) {
  var jsget = new Image();
  jsget.src = stringOrHref(elem);
  return false;
}

function inline(id, url, params) {
  $(id).innerHTML = "<img src=\"waiting.gif\"/>";
  new Ajax.Request(stringOrHref(url),
      {
        method: 'get',
        parameters: params,
        onSuccess: function(response) {
          $(id).innerHTML = response.responseText;
        }
      });
  return false;
}

function del(elem) {
  try {
    elem.parentNode.removeChild(elem);
  } catch(err){}
}



function toggleLink(elem) {
  var base = elem.className.replace(/_[^_]*$/, '');
  var onelems = $$('.'+base+'_on');
  var offelems = $$('.'+base+'_off');
  if (onelems[0].style.display == 'none') {
    for (i=0; i < onelems.length; ++i) {
      onelems[i].style.display = 'inline';
    }
    for (i=0; i < offelems.length; ++i) {
      offelems[i].style.display = 'none';
    }
  }
  else {
    for (i=0; i < onelems.length; ++i) {
      onelems[i].style.display = 'none';
    }
    for (i=0; i < offelems.length; ++i) {
      offelems[i].style.display = 'inline';
    }
  }
}



var history_size = 25;

function gen_jslink(text, onclick) {
  return "<a href=\"#\" onclick=\""+onclick+"\">"+text+"</a>";
}
function gen_inline(id, url) {
  return "inline('"+id+"', '"+url+"')";
}

function pushHistory(station, doc, params) {
  var elem = $('outcome_'+doc);
  elem.className = "outcome_icon "+params.replace(/.*outcome=([^&]*).*/, "outcome_$1");

  src = $$('#doc_'+doc+' .history');
  new Insertion.Top('history-elems', src[0].innerHTML);

  if($('history-elems').childNodes.length > history_size) {
    for(len = $('history-elems').childNodes.length; len > history_size; --len) {
      $('history-elems').removeChild($('history-elems').childNodes[len-1]);
    }

    if($('history').childNodes[0].childNodes.length <= 1) {
      $('history').childNodes[0].innerHTML =
      $('history').childNodes[2].innerHTML =
        gen_jslink("&laquo;older",
          gen_inline('history',
                '/history?from='+history_size+'&station='+escape(station))) +
        "&nbsp;newer&raquo;";
    }
  }

  $('content').innerHTML = "<img src=\"waiting.gif\"/>";
  scroll(0, 0);
  new Ajax.Request("/docupdate",
      {
        method: 'post',
        parameters: 'doc='+escape(doc)+'&'+'station='+escape(station)+'&'+params,
        onSuccess: function(response) {
          $('content').innerHTML = response.responseText;
          runScripts($('content'));
        }
      });
  return false;
}

function showDoc(station, doc) {
  $('content').innerHTML = "<img src=\"waiting.gif\"/>";
  new Ajax.Request("/doc",
      {
        method: 'get',
        parameters: 'doc='+escape(doc)+'&station='+escape(station),
        onSuccess: function(response) {
          del($('history_'+doc));
          $('content').innerHTML = response.responseText;
          runScripts($('content'));
        }
      });
  return false;
}

function updateTickerContents() {
  new Ajax.Request("/tickupdate",
      {
        onSuccess: function(response) {
          $('TICKER2').innerHTML = response.responseText;
        },

        onComplete: function(response) {
          window.setTimeout("updateTickerContents()", 10000);
        }
      });
  return false;
}
