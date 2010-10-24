function setupScroll() {
  $(window).scroll(function() {
    insensitiveToScroll(function() {
      if ($(window).scrollTop() + $(window).height()
            >= $(document).height() - /* prefetch buffer */$(window).height()) {
        nextScrollDoc(5);
      }
    });
  });
}

function nextScrollDoc(remaining) {
  moreDocsFrom('scrollview', 'remaining='+remaining+'&for='+location.href, 'rwscrollcontent');
}

function moreDocsFrom(url, params, id) {
  new $.ajax({
        url: url,
        type: 'post',
        data: params,
        success: function(response) {
          $i(id).innerHTML += response;
          runScripts($i(id));
        }
      });
  return false;
}

function maybeRemoveExpanders() {
  var posts = $('.rwpost-contents');
  for (var i = 0; i < posts.length; ++i) {
    if (posts[i].clientHeight < 300) {
      $('#expand_'+posts[i].id).hide();
    }
  }
}

function scrollLike(doc) {
  var elem = $('#doc_'+doc);
  elem.fadeTo('fast', 0.8);
  elem.next().fadeTo('fast', 0.8);
  jsget("/vote?doc="+escape(doc)+'&outcome=4');
}

function scrollSkip(doc) {
  var elem = $('#doc_'+doc);
  elem.fadeOut('fast');
  elem.next().fadeOut('fast');
  jsget("/vote?doc="+escape(doc)+'&outcome=1');
}

function scrollHide(doc) {
  var elem = $('#doc_'+doc);
  elem.fadeOut('fast');
  elem.next().fadeOut('fast');
}

function moveUp() {
  var elem = $('.rwcurrent');
  elem.removeClass('rwcurrent');
  if (elem.prev().length == 0)
    elem.addClass('rwcurrent');
  else
    elem.prev().addClass('rwcurrent');
  scrollTo('.rwcurrent');
  return false;
}

function moveDown() {
  var elem = $('.rwcurrent');
  elem.removeClass('rwcurrent');
  if (elem.next().length == 0)
    elem.addClass('rwcurrent');
  else
    elem.next().addClass('rwcurrent');
  scrollTo('.rwcurrent');
  return false;
}

function scrollTo(selector) {
  var currScroll = $(window).scrollTop();
  var target = $(selector).offset().top;
  if (target < currScroll || target > currScroll + window.screen.height*0.7) {
    $('html,body').scrollTop(target);
  }
}

function clickCurrentLike() {
  $('.rwcurrent .rwscrolllike').click();
  return false;
}

function clickCurrentSkip() {
  $('.rwcurrent .rwscrollskip').click();
  return false;
}

function clickCurrentHide() {
  $('.rwcurrent .rwscrollhidebutton').click();
  return false;
}



function renderFlash() {
  var hash = location.hash.substring(1);
  newDocFrom('flashview', 'hash='+escape(hash)+'&remaining=5');
}

function flashVote(vote, outcome) {
  $('#rwflashcontent .rwflash'+vote).addClass('rwflashhover');
  var doc = $('#rwflashcontent .rwflashdoc').attr('id').substring(4);
  setTimeout(function() {
    docUpdate(doc, "outcome="+outcome);
  }, 20);
  return false;
}
function flashLike() { return flashVote('like', '4'); }
function flashNext() { return flashVote('next', '2'); }
function flashSkip() { return flashVote('skip', '1'); }

function docUpdate(doc, params) {
  scrollUp();
  if ($i('rwflashprefetch').children.length < 2) {
    prefetchDocFrom('flashview', 'remaining=5');
  }

  if ($i('rwflashprefetch').children.length > 0) {
    jsget("/vote?doc="+escape(doc)+'&'+params);
    $('#rwflashcontent').empty();
    withoutRerenderingDoc(function() {
      $('#rwflashcontent').append($i('rwflashprefetch').children[0]);
      runScripts($i('rwflashcontent'));
    });
    return false;
  } else {
    return newDocFrom('flashview', 'doc='+escape(doc)+'&remaining=5&'+params);
  }
}

function newDocFrom(url, params) {
  $i('rwflashcontent').innerHTML = "<img src=\"waiting.gif\" class=\"rwshadow\"/>";
  new $.ajax({
        url: url,
        type: 'post',
        data: params,
        success: function(response) {
          withoutRerenderingDoc(function() {
            $i('rwflashcontent').innerHTML = response;
            runScripts($i('rwflashcontent'));
          });
        }
      });
  return false;
}

function prefetchDocFrom(url, params) {
  new $.ajax({
        url: url,
        type: 'post',
        data: params,
        success: function(response) {
          withoutRerenderingDoc(function() {
            $i('rwflashprefetch').innerHTML += response;
          });
        }
      });
  return false;
}

function scrollUp() {
  scroll(0, 0);
  $i('rwbody').scrollTop = 0;
}

function withoutRerenderingDoc(f) {
  $(window).unbind('hashchange');

  f();

  setTimeout(function() {
    $(window).bind('hashchange', renderFlash);
  }, 500);
}

