var pageSize = 0;

var logger = null;
function log_write(aString) {
  if ((logger == null) || (logger.closed)) {
    // TODO Doesn't work, but works from js console. So must manually open once.
    logger = window.open("","log","width=640,height=480,resizable,scrollbars=1");
    logger.document.open("text/plain");
  }
  logger.document.write(timestamp()+" "+pageSize+" -- "+aString+"\n");
}

function timestamp() {
  var currentTime = new Date();
  return currentTime.getMinutes()+":"+currentTime.getSeconds();
}

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

function deleteScripts(e) {
  // we don't want to run these next time we call runScripts.
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

function del(elem) {
  try {
    elem.parentNode.removeChild(elem);
  } catch(err){}
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



var scrollOn = true;
function insensitiveToScroll(f) {
  if (scrollOn) {
    scrollOn = false;
    f();
    setTimeout(function() { scrollOn = true;}, 500);
  }
}

function updateLocation(l) {
  if (!location.hash)
    window.location.replace(l);
  else
    location.href = l;
}
