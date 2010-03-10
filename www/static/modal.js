(function () {

// add the onType "M" to toggle the modal.
// also catch and toggle focus events.
var focusedElement = null;

var modal = document.getElementById('modal');
var dialog = document.getElementById('dialog');
var body = document.getElementById('body');
var html = document.documentElement;

var modalShowing = (html.className === 'modal');

html.tabIndex = -1;
dialog.tabIndex = -1;
body.tabIndex = -1;

// Have to hack for Safari, due to poor support for the focus() function.
try {
        var isSafari = window.navigator.vendor.match(/Apple/);
} catch (ex) {
        isSafari = false;
}
if ( isSafari ) {
        var dialogFocuser = document.createElement('a');
        dialogFocuser.href="#";
        dialogFocuser.style.display='block';
        dialogFocuser.style.height='0';
        dialogFocuser.style.width='0';
        dialogFocuser.style.position = 'absolute';
        dialog.insertBefore(dialogFocuser, dialog.firstChild);
} else {
        dialogFocuser = dialog;
}

var rand = function (min,max) {
        var n = Math.random();
        return parseInt(min + (n * (max-min)));
};
var randColor = function () {
        return 'rgb('+rand(0,255)+','+rand(0,255)+','+rand(0,255)+')';
};

window.onunload = function () {
        dialogFocuser = focusedElement = modal = dialog = body = html = null;
};

var onfocus = function (e) {
        e = e || window.event;
        var el = e.target || e.srcElement;
/*
        if ( modalShowing ) {
                body.style.backgroundColor = randColor();
                body.style.color = randColor();
        } else {
                body.style.backgroundColor = '#fff';
                body.style.color = '#000';
        }
*/      
        // save the last focused element when the modal is hidden.
        if ( !modalShowing ) {
                focusedElement = el;
                return;
        }
        
        // if we're focusing the dialog, then just clear the blurring flag.
        // else, focus the dialog and prevent the other event.
        var p = el.parentNode;
        while ( p && p.parentNode && p !== dialog ) {
                p=p.parentNode;
        }
        if ( p !== dialog ) {
                dialogFocuser.focus();
        }
};



var onblur = function () {
        if ( !modalShowing ) {
                focusedElement = body;
        }
};

html.onfocus = html.onfocusin = onfocus;
html.onblur = html.onfocusout = onblur;
if ( isSafari ) {
        html.addEventListener('DOMFocusIn',onfocus);
        html.addEventListener('DOMFocusOut',onblur);
}
// focus and blur events are tricky to bubble.
// need to do some special stuff to handle MSIE.




// toggle the modal.
// when it hides, focus the prior focused element.
html.onkeypress = function(e){
        e=e||window.event;
        
        var code = e.which || e.keyCode;
        
        // m or M
        if ( code !== 109 && code !== 77 ) {
                return true;
        }
        
        e.preventDefault && e.preventDefault();
        e.returnValue = false;
        
        toggleModal();
        
        return false;
};

var toggleModal = function () {
        
        html.className=modalShowing?'':'modal';
        modalShowing = !modalShowing;
        if (modalShowing) {
                dialog.focus();
        } else if (focusedElement) {
                try {
                        focusedElement.focus();
                } catch(ex) {}
        }
        
};

})();
