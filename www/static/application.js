function jsget(elem) {
  var jsget = new Image();
  jsget.src = elem.href;
  return false;
}

function inline(id, url, params) {
  $(id).innerHTML = "<img src=\"waiting.gif\"/>";
  new Ajax.Request(url,
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



function pushHistory(station, doc, params) {
  var elem = $('outcome_'+doc);
  elem.className = "outcome_icon "+params.replace(/.*outcome=([^&]*).*/, "outcome_$1");

  src = $$('#doc_'+doc+' .history');
  new Insertion.Top('history-elems', src[0].innerHTML);

  for(len = $('history-elems').childNodes.length; len > 10; --len) {
    $('history-elems').removeChild($('history-elems').childNodes[len-1]);
  }

  $('content').innerHTML = "<img src=\"waiting.gif\"/>";
  new Ajax.Request("/docupdate",
      {
        method: 'post',
        parameters: 'doc='+doc+'&'+'station='+station+'&'+params,
        onSuccess: function(response) {
          $('content').innerHTML = response.responseText;
        }
      });
  return false;
}

function showDoc(station, doc) {
  $('content').innerHTML = "<img src=\"waiting.gif\"/>";
  new Ajax.Request("/doc",
      {
        method: 'get',
        parameters: 'doc='+doc+'&station='+station,
        onSuccess: function(response) {
          del($('history_'+doc));
          $('content').innerHTML = response.responseText;
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
updateTickerContents();

window.onload = function() { $('newstationform').focus(); };
