function setupScroll() {
  $(window).scroll(function() {
    insensitiveToScroll(function() {
      if ($(window).scrollTop() + $(window).height()
            >= $(document).height() - /* prefetch buffer */$(window).height()) {
        moreDocsFrom('scrollview', '');
      }
    });
  });
}

function moreDocsFrom(url, params) {
  $('#spinner').fadeIn();
  new $.ajax({
        url: url,
        type: 'post',
        data: params,
        success: function(response) {
          $i('rwscrollcontent').innerHTML += response;
          runScripts($i('rwscrollcontent'));
          deleteScripts($i('rwscrollcontent'));
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
  newDocFrom('flashview', 'hash='+escape(hash));
}

function docUpdate(doc, params) {
  return newDocFrom('flashview', 'doc='+escape(doc)+'&'+params);
}

function newDocFrom(url, params) {
  prepareNewDoc('rwflashcontent');
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

