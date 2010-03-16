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
  prepareAjax(id);
  new Ajax.Request(stringOrHref(url),
      {
        method: 'get',
        parameters: params,
        onSuccess: function(response) {
          $(id).innerHTML = response.responseText;
          checkContent(id);
          runScripts($(id));
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

  prepareAjax('content');
  new Ajax.Request("/docupdate",
      {
        method: 'post',
        parameters: 'doc='+escape(doc)+'&'+'station='+escape(station)+'&'+params,
        onSuccess: function(response) {
          $('content').innerHTML = response.responseText;
          checkContent('content');
          runScripts($('content'));
        }
      });
  return false;
}

function showDoc(station, doc) {
  prepareAjax('content');
  new Ajax.Request("/doc",
      {
        method: 'get',
        parameters: 'doc='+escape(doc)+'&station='+escape(station),
        onSuccess: function(response) {
          del($('history_'+doc));
          $('content').innerHTML = response.responseText;
          checkContent('content');
          runScripts($('content'));
        }
      });
  return false;
}

var readwarp_waitGif = "waiting.gif";
var readwarp_waitMsg = "<img src=\"" + readwarp_waitGif + "\"/>";
var readwarp_msgCount = 0;
function prepareAjax(id) {
  scroll(0, 0);
  $('body').scrollTop = 0;
  $(id).innerHTML = readwarp_waitMsg;
  ++readwarp_msgCount;
  setTimeout("errorMessage('"+id+"', "+readwarp_msgCount+");", 5000);
}

function errorMessage(id, count) {
  if (readwarp_msgCount != count) return;

  var elem = $(id).innerHTML;
  var msgToAdd = " Hmm, still waiting. You may want to try reloading this page.";
  if (elem.indexOf(readwarp_waitGif) > 0
      && elem.length < readwarp_waitMsg.length+msgToAdd.length - 5) {
    $(id).innerHTML += msgToAdd;
  }
}

function checkContent(id) {
  if ($(id).innerHTML.length < 100) {
    $(id).innerHTML = "Didn't get back the next story. Sorry about that; please try reloading this page.";
  }
}
