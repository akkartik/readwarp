function setupScroll() {
  $(window).scroll(function() {
    insensitiveToScroll(function() {
      if ($(window).scrollTop() + $(window).height()
            >= $(document).height() - /* prefetch buffer */$(window).height()) {
        moreDocsFrom('scrollview', 'remaining=5', 'rwscrollcontent');
      }
    });
  });
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

function downvote(doc) {
  jsget("/vote?doc="+escape(doc)+'&outcome=1');
}

function upvote(doc) {
  jsget("/vote?doc="+escape(doc)+'&outcome=4');
}

function maybeRemoveExpanders() {
  var posts = $('.rwpost-contents');
  for (var i = 0; i < posts.length; ++i) {
    if (posts[i].clientHeight < 300) {
      $('#expand_'+posts[i].id).hide();
    }
  }
}



function renderFlash() {
  var hash = location.hash.substring(1);
  newDocFrom('flashview', 'hash='+escape(hash)+'&remaining=5');
}

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

