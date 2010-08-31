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



function newDocFrom(url, params) {
  $('#spinner').fadeIn();
  new $.ajax({
        url: url,
        type: 'post',
        data: params,
        success: function(response) {
          $i('rwcontent').innerHTML += response;
          runScripts($i('rwcontent'));
          deleteScripts($i('rwcontent'));
          $('#spinner').fadeOut();
        }
      });
  return false;
}

function showDoc() {
  return newDocFrom('doc', '');
}

function downvote(doc) {
  jsget("/vote?doc="+escape(doc)+'&outcome=1');
}

function upvote(doc) {
  jsget("/vote?doc="+escape(doc)+'&outcome=4');
}

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

var scrollOn = true;
function setupScroll() {
  $(window).scroll(function() {
    insensitiveToScroll(function() {
      if ($(window).scrollTop() + $(window).height()
            >= $(document).height() - /* prefetch buffer */$(window).height()) {
        showDoc();
      }
    });
  });
}

function maybeRemoveExpanders() {
  var posts = $('.rwpost-contents');
  for (var i = 0; i < posts.length; ++i) {
    if (posts[i].clientHeight < 350) {
      $('#expand_'+posts[i].id).hide();
    }
  }
}

function sameSite(doc) {
  swooshLeft();
  $('#spinner').fadeIn();
  new $.ajax({
        url: '/samesite',
        type: 'post',
        data: 'doc='+escape(doc),
        success: function(response) {
          $i('rwcontent').innerHTML = response;
          runScripts($i('rwcontent'));
          deleteScripts($i('rwcontent'));
          $('#spinner').fadeOut();
        }
      });
  return false;
}

function swooshLeft() {
  var elems = $('.rwpost-wrapper');
  for (var i = 0; i < elems.length; ++i) {
    var elem = $(elems[i].parentNode); // HACK
    elem.animate({'margin-left':-1*$(window).width()},
                 {complete: hidefn(elem)});
  }
}

function hidefn(elem) {
  return function() {elem.hide();};
}

function insensitiveToScroll(f) {
  if (scrollOn) {
    scrollOn = false;
    f();
    setTimeout(function() { scrollOn = true;}, 500);
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
