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
  moreDocsFrom('scrollview', 'remaining='+remaining+'&for='+escape(location.href), 'rwscrollcontent');
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

function clickCurrentExpander() {
  $('.rwcurrent .rwexpander').click();
  return false;
}
