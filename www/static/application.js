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

function submitForm(elem) {
  while (elem && elem.tagName !== 'FORM') {
    elem = elem.parentNode;
  }
  elem.submit();
  return false;
}

function submitMagicBox(id, msg) {
  if ($(id).value !== msg) {
    askFor($(id).value);
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
  new Ajax.Request(stringOrHref(url),
      {
        method: 'post',
        parameters: params
      });
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



function gen_jslink(text, onclick) {
  return "<a href=\"#\" onclick=\""+onclick+"\">"+text+"</a>";
}
function gen_inline(id, url) {
  return "inline('"+id+"', '"+url+"')";
}

function newDocFrom(url, params) {
  prepareAjax('rwcontent');
  new Ajax.Request(url,
      {
        method: 'post',
        parameters: params,
        onSuccess: function(response) {
          $('rwcontent').innerHTML = response.responseText;
          checkContent('rwcontent');
          runScripts($('rwcontent'));
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
  prepareAjax('rwcontent');
  new Ajax.Request("/doc",
      {
        method: 'get',
        parameters: 'doc='+escape(doc),
        onSuccess: function(response) {
          $('rwcontent').innerHTML = response.responseText;
          checkContent('rwcontent');
          runScripts($('rwcontent'));
        }
      });
  return false;
}

var readwarp_waitGif = "waiting.gif";
var readwarp_waitMsg = "<img src=\"" + readwarp_waitGif + "\" class=\"rwshadow\"/>";
var readwarp_msgCount = 0;
function prepareAjax(id) {
  scroll(0, 0);
  $('rwbody').scrollTop = 0;
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
  if ($(id).innerHTML.length < 10) {
    $(id).innerHTML = "Didn't get back the next story. Sorry about that; please try reloading this page.";
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
