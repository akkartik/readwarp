// WebTicker by Mioplanet
// www.mioplanet.com

TICKER_CONTENT = $("TICKER").innerHTML;
 
TICKER_SPEED = 2;
TICKER_STYLE = "font-family:serif; font-size:1.5em; color:#444444;";
TICKER_PAUSED = false;

ticker_start();

function ticker_start() {
	var tickerSupported = false;
	TICKER_WIDTH = $("TICKER").style.width;
	var img = "<img src=ticker_space.gif width="+TICKER_WIDTH+" height=0>";

	// Firefox
	if (navigator.userAgent.indexOf("Firefox")!=-1 || navigator.userAgent.indexOf("Safari")!=-1) {
		$("TICKER").innerHTML = "<TABLE  cellspacing='0' cellpadding='0' width='100%'><TR><TD nowrap='nowrap'>"+img+"<SPAN style='"+TICKER_STYLE+"' ID='TICKER_BODY' width='100%'>&nbsp;</SPAN>"+img+"</TD></TR></TABLE>";
		tickerSupported = true;
	}
	// IE
	if (navigator.userAgent.indexOf("MSIE")!=-1 && navigator.userAgent.indexOf("Opera")==-1) {
		$("TICKER").innerHTML = "<DIV nowrap='nowrap' style='width:100%;'>"+img+"<SPAN style='"+TICKER_STYLE+"' ID='TICKER_BODY' width='100%'></SPAN>"+img+"</DIV>";
		tickerSupported = true;
	}
	if(!tickerSupported) $("TICKER").outerHTML = ""; else {
		$("TICKER").scrollLeft = 1000;
		$("TICKER_BODY").innerHTML = TICKER_CONTENT;
		$("TICKER").style.display="block";
		TICKER_tick();
	}
}

function TICKER_tick() {
	if(!TICKER_PAUSED)
    $("TICKER").scrollLeft += TICKER_SPEED;

	if($("TICKER").scrollLeft >= $("TICKER").scrollWidth - $("TICKER").offsetWidth) {
    $("TICKER").scrollLeft = 0;
    if ($("TICKER2").innerHTML.length > 0) {
      $("TICKER_BODY").innerHTML = $("TICKER2").innerHTML;
      $("TICKER2").innerHTML = '';
    }
  }

	window.setTimeout("TICKER_tick()", 30);
}
