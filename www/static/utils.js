var pageSize = 0;

var logger = null;
function log_write(aString) {
  if ((logger == null) || (logger.closed)) {
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

function runScripts(e, toplevel) {
  if (e.nodeType != 1) return;

  if (toplevel === undefined) log_write('runScripts');
  if (e.tagName.toLowerCase() == 'script') {
    log_write('script');
    eval(e.text);
  }
  else {
    for(var i = 0; i < e.children.length; ++i) {
      runScripts(e.children[i], false);
    }
  }
}

function deleteScripts(e) {
  log_write('deleteScripts');
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

function inline(id, url, params) {
  new $.ajax({
        url: stringOrHref(url),
        type: 'get',
        data: params,
        success: function(response) {
          $i(id).innerHTML = response;
          runScripts($i(id));
          deleteScripts($i(id));
        }
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
  log_write('updateLocation');
  if (!location.hash) {
    log_write('a');
    window.location.replace(l);
  } else {
    log_write('b');
    location.href = l;
  }
}
