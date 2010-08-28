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

function runScriptsOnce(e) {
  if (e.nodeType != 1) return;

  if (e.tagName.toLowerCase() == 'script') {
    eval(e.text);
  }
  else {
    for(var i = 0; i < e.children.length; ++i) {
      runScriptsOnce(e.children[i]);
    }
  }

  // we don't want to run these next time we call runScriptsOnce.
  scripts = $('script');
  for (var i = 0; i < scripts.length; ++i) {
    scripts[i].parentNode.removeChild(scripts[i]);
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
  new $.ajax({
        url: stringOrHref(url),
        type: 'get',
        data: params,
        success: function(response) {
          $i(id).innerHTML = response;
          runScriptsOnce($i(id));
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
  new $.ajax({
        url: url,
        type: 'post',
        data: params,
        success: function(response) {
          $i('rwcontent').innerHTML += response;
          runScriptsOnce($i('rwcontent'));
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


var logger = null;
function log_write(aString) {
  if ((logger == null) || (logger.closed)) {
    // Doesn't work, but works from js console. So must manually open once.
    logger = window.open("","log","width=640,height=480,resizable,scrollbars=1");
    logger.document.open("text/plain");
  }
  logger.document.write(timestamp()+" "+pageSize+" -- "+aString+"\n");
}

function timestamp() {
  var currentTime = new Date();
  return currentTime.getMinutes()+":"+currentTime.getSeconds();
}


//TODO: better name
var scrollOn = true;
function renderDoc() {
  showDoc(location.hash.substring(1));
  //checkRenderMore();
  $(window).scroll(function() {
    log_write(scrollOn+" "+$(window).scrollTop()+" "+$(window).height()+" "+$(document).height());
    if (scrollOn && $(window).scrollTop() + $(window).height() >= 0.8*$(document).height()) {
      scrollOn = false;
      log_write("load");
      setTimeout(function() { newDocFrom('docupdate'); }, 100);
      setTimeout(function() { scrollOn = true;}, 500);
    }
    log_write("done");
  });
}

function checkRenderMore() {
          if ($(window).scrollTop() + $(window).height() >= 0.8*$(document).height()) {
            newDocFrom('docupdate');
            setTimeout(checkRenderMore, 1000);
          }
}

function withoutRerenderingDoc(f) {
  $(window).unbind('hashchange');

  f();

  setTimeout(function() {
    $(window).bind('hashchange', renderDoc);
  }, 500);
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
