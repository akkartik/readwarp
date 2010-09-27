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
  $('#spinner').fadeIn();
  new $.ajax({
        url: url,
        type: 'post',
        data: params,
        success: function(response) {
          $i(id).innerHTML += response;
          runScripts($i(id));
          $('#spinner').fadeOut();
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
  newDocFrom('flashview', 'hash='+escape(hash)+'&remaining=2', 'rwflashcontent');
}

function docUpdate(doc, params) {
  if ($i('rwflashprefetch').children.length > 0) {
    jsget("/vote?doc="+escape(doc)+'&'+params);
    $('#rwflashcontent').empty();
    $('#rwflashcontent').append($i('rwflashprefetch').children[0]);
    return false;
  }
  return newDocFrom('flashview', 'doc='+escape(doc)+'&remaining=1&'+params, 'rwflashcontent'); // XXX higher remaining causes infinite loads
}

function newDocFrom(url, params, id) {
  prepareNewDoc(id);
  new $.ajax({
        url: url,
        type: 'post',
        data: params,
        success: function(response) {
          withoutRerenderingDoc(function() {
            $i(id).innerHTML = response;
            runScripts($i(id));
          });
        }
      });
  return false;
}

function prefetchDoc() {
  alert('foo2');
  return moreDocsFrom('flashview', 'remaining=5', 'rwflashprefetch');
}

function prepareNewDoc(id) {
  scroll(0, 0);
  $i('rwbody').scrollTop = 0;
  $i(id).innerHTML = "<img src=\"waiting.gif\" class=\"rwshadow\"/>";
}

function withoutRerenderingDoc(f) {
  $(window).unbind('hashchange');

  f();

  setTimeout(function() {
    $(window).bind('hashchange', renderFlash);
  }, 500);
}

