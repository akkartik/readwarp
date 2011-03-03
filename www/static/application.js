var rowsPerUpdate = 5;
var numColumns = 0;
var currColumn = 0;
function initPage() {
  setupColumns();
  nextScrollDoc(rowsPerUpdate*numColumns);
  setTimeout(setupCurrentStory, 5000);
}

function nextScrollDoc(remaining) {
  moreDocsFrom('scrollview', remaining, 'remaining='+remaining+'&for='+escape(location.href), 'rwscrollcolumn'+remaining%numColumns);
}

function moreDocsFrom(url, remaining, params, id) {
  $('#morebutton').html('loading...');
  new $.ajax({
        url: url,
        type: 'post',
        data: params,
        success: function(response) {
          var callback = function() {
            $i(id).innerHTML += response;
            runScripts($i(id));
          };

          if (remaining <= 1) {
            callback();
            $('#morebutton').html('More &darr;');
            $('#morebutton').show();
          } else {
            $('#morebutton').fadeOut(200, callback);
          }
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

function setupCurrentStory() {
  $('#rwscrollcolumn'+currColumn+' .rwscrollpost-wrapper:first').addClass('rwcurrent');
}

function moveUp() {
  var elem = $('.rwcurrent');
  elem.removeClass('rwcurrent');
  // HACK
  if (elem.prev().prev().length == 0)
    elem.addClass('rwcurrent');
  else
    elem.prev().prev().addClass('rwcurrent');
  scrollTo('.rwcurrent');
  return false;
}

function moveDown() {
  var elem = $('.rwcurrent');
  elem.removeClass('rwcurrent');
  if (elem.next().next().length == 0)
    elem.addClass('rwcurrent');
  else
    elem.next().next().addClass('rwcurrent');
  scrollTo('.rwcurrent');
  return false;
}

function scrollTo(selector) {
  $('html,body').scrollTop($(selector).offset().top-30);
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

function makeCurrent(elem) {
  $('.rwcurrent').removeClass('rwcurrent');
  $(elem).addClass('rwcurrent');
  return false;
}



function setupColumns() {
  // sync with main.css
  var columnWidth = 520; // #rwscrollpage, img
  var intercolumnGutter = 20; // .rwgutter, .rwscrollcolumn

  var oldNumColumns = numColumns;
  numColumns = intDiv(window.innerWidth, columnWidth);
  if (numColumns < 1) numColumns = 1;
  if (numColumns <= oldNumColumns) return;

  $('#rwscrollpage')[0].style.width = (numColumns-1)*(columnWidth+intercolumnGutter) + columnWidth + 'px';
  for (var i = 0; i < numColumns-1; ++i) {
    $('#rwscrollcontent').append('<div id="rwscrollcolumn'+i+'" class="rwscrollcolumn"></div>');
  }
  $('#rwscrollcontent').append('<div id="rwscrollcolumn'+(numColumns-1)+'" class="rwscrollcolumn rwscrollcolumn-last"></div>');
  $('#rwscrollcontent').append('<div class="rwclear"></div>');
}

function pickFromColumn(elem, column, targetScroll) {
  if (column.length == 0) {
    return false;
  }

  children = column.children('.rwscrollpost-wrapper');
  for (var i = 0; i < children.length; ++i) {
    if ($(children[i]).offset().top > targetScroll+50)
      break;
  }

  if (i-1 >= 0) {
    elem.removeClass('rwcurrent');
    $(children[i-1]).addClass('rwcurrent');
  }
  return false;
}

function moveLeft() {
  var elem = $('.rwcurrent');
  return pickFromColumn(elem, elem.parent().prev(), elem.offset().top);
}

function moveRight() {
  var elem = $('.rwcurrent');
  return pickFromColumn(elem, elem.parent().next(), elem.offset().top);
}

function intDiv(a, b) {
  return (a - a%b) / b;
}
