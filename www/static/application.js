var pageSize = 0;

function notblank(s) {
  return s && s != '';
}

function fillDefault(elem, msg) {
  if (elem.value === '') {
    elem.value = msg;
    elem.style.color = '#999';
  }
}
function clearDefault(elem, msg) {
  if (elem.value === msg) {
    elem.value = '';
    elem.style.color = '#000';
  }
}

function $i(id) {
  return $('#'+id)[0];
}

function submitMagicBox(id, msg) {
  if ($i(id).value !== msg) {
    askFor($i(id).value);
  }
  return false;
}

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

function jspost(url, params) {
  new $.ajax({
        url: stringOrHref(url),
        type: 'post',
        data: params
      });
  return false;
}

function inline(id, url, params) {
  prepareAjax(id);
  new $.ajax({
        url: stringOrHref(url),
        type: 'get',
        data: params,
        success: function(response) {
          $i(id).innerHTML = response;
          checkContent(id);
          runScripts($i(id));
        }
      });
  return false;
}

function del(elem) {
  try {
    elem.parentNode.removeChild(elem);
  } catch(err){}
}



function newDocFrom(url, params) {
  prepareAjax('rwcontent');
  new $.ajax({
        url: url,
        type: 'post',
        data: params,
        success: function(response) {
          withoutRerenderingDoc(function() {
            $i('rwcontent').innerHTML = response;
            checkContent('rwcontent');
            runScripts($i('rwcontent'));
          });
        }
      });
  return false;
}

function docUpdate(doc, params) {
  return newDocFrom('docupdate', 'doc='+escape(doc)+'&'+params);
}

function askFor(query) {
  return newDocFrom('askfor', 'q='+escape(query));
}

function showDoc(doc) {
  return newDocFrom('doc', 'id='+escape(doc));
}

function renderDoc() {
  showDoc(location.hash.substring(1));
}

function withoutRerenderingDoc(f) {
  $(window).unbind('hashchange');

  f();

  setTimeout(function() {
    $(window).bind('hashchange', renderDoc);
  }, 500);
}

var readwarp_waitGif = "waiting.gif";
var readwarp_waitMsg = "<img src=\"" + readwarp_waitGif + "\" class=\"rwshadow\"/>";
var readwarp_msgCount = 0;
function prepareAjax(id) {
  scroll(0, 0);
  $i('rwbody').scrollTop = 0;
  $i(id).innerHTML = readwarp_waitMsg;
  ++readwarp_msgCount;
  setTimeout("errorMessage('"+id+"', "+readwarp_msgCount+");", 5000);
}

function errorMessage(id, count) {
  if (readwarp_msgCount != count) return;

  var elem = $i(id).innerHTML;
  var msgToAdd = " Hmm, still waiting. You may want to try reloading this page.";
  if (elem.indexOf(readwarp_waitGif) > 0
      && elem.length < readwarp_waitMsg.length+msgToAdd.length - 5) {
    $i(id).innerHTML += msgToAdd;
  }
}

function checkContent(id) {
  if ($i(id).innerHTML.length < 10) {
    $i(id).innerHTML = "Didn't get back the next story. Sorry about that; please try reloading this page.";
  }
}

function params(elem) {
  var ans = {};
  var inputs = elem.getElementsByTagName('input');
  for (var i=0; i < inputs.length; ++i) {
    if (inputs[i].type == "checkbox") {
      ans[inputs[i].name] = inputs[i].checked;
    }
    else {
      ans[inputs[i].name] = inputs[i].value;
    }
  }

  var inputs = elem.getElementsByTagName('select');
  for (var i = 0; i < inputs.length; ++i) {
    ans[inputs[i].name] = inputs[i].options[inputs[i].selectedIndex].value;
  }

  var inputs = elem.getElementsByTagName('textarea');
  for (var i = 0; i < inputs.length; ++i) {
    ans[inputs[i].name] = inputs[i].value;
  }

  return ans;
}

function updateLocation(l) {
  if (!location.hash)
    window.location.replace(l);
  else
    location.href = l;
}
