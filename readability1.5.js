var readability = {
    version:     '1.5.0',
    emailSrc:    'http://lab.arc90.com/experiments/readability/email.php',
    flags: 0x1 | 0x2,
    
    FLAG_STRIP_UNLIKELYS: 0x1,
    FLAG_WEIGHT_CLASSES:  0x2,
    
    regexps: {
        unlikelyCandidatesRe:   /combx|comment|disqus|foot|header|menu|meta|rss|shoutbox|sidebar|sponsor/i,
        okMaybeItsACandidateRe: /and|article|body|column|main/i,
        positiveRe:             /article|body|content|entry|hentry|page|pagination|post|text/i,
        negativeRe:             /combx|comment|contact|foot|footer|footnote|link|media|meta|promo|related|scroll|shoutbox|sponsor|tags|widget/i,
        divToPElementsRe:       /<(a|blockquote|dl|div|img|ol|p|pre|table|ul)/i,
        replaceBrsRe:           /(<br[^>]*>[ \n\r\t]*){2,}/gi,
        replaceFontsRe:         /<(\/?)font[^>]*>/gi,
        trimRe:                 /^\s+|\s+$/g,
        normalizeRe:            /\s{2,}/g,
        killBreaksRe:           /(<br\s*\/?>(\s|&nbsp;?)*){1,}/g,
        videoRe:                /http:\/\/(www\.)?(youtube|vimeo)\.com/i
    },

    /**
     *  1. Prep the document by removing script tags, css, etc.
     *  3. Grab the article content from the current dom tree.
     **/
    init: function() {
        readability.prepDocument();

        var articleContent = readability.grabArticle();

        if(readability.getInnerText(articleContent, false).length < 500) {
            if (readability.flagIsActive(readability.FLAG_STRIP_UNLIKELYS)) {
                readability.removeFlag(readability.FLAG_STRIP_UNLIKELYS);
                document.body.innerHTML = readability.bodyCache;
                return readability.init();
            }
            else if (readability.flagIsActive(readability.FLAG_WEIGHT_CLASSES)) {
                readability.removeFlag(readability.FLAG_WEIGHT_CLASSES);
                document.body.innerHTML = readability.bodyCache;
                return readability.init();              
            }
        }
    },

    getArticleTitle: function () {
        var curTitle = document.title;

        if(curTitle.match(/ [\|\-] /))
        {
            curTitle = document.title.replace(/(.*)[\|\-] .*/gi,'$1');
            
            if(curTitle.split(' ').length < 3) {
                curTitle = document.title.replace(/[^\|\-]*[\|\-](.*)/gi,'$1');
            }
        }
        else if(curTitle.indexOf(': ') !== -1)
        {
            curTitle = document.title.replace(/.*:(.*)/gi, '$1');

            if(curTitle.split(' ').length < 3) {
                curTitle = document.title.replace(/[^:]*[:](.*)/gi,'$1');
            }
        }
        else if(curTitle.length > 150 || curTitle.length < 15)
        {
            var hOnes = document.getElementsByTagName('h1');
            if(hOnes.length == 1)
            {
                curTitle = readability.getInnerText(hOnes[0]);
            }
        }

        curTitle = curTitle.replace( readability.regexps.trimRe, "" );

        if(curTitle.split(' ').length <= 4) {
            curTitle = document.title;
        }
        
        var articleTitle = document.createElement("H1");
        articleTitle.innerHTML = curTitle;
        
        return articleTitle;
    },

    prepDocument: function () {
        var frames = document.getElementsByTagName('frame');
        if(frames.length > 0) {
            var bestFrame = null;
            var bestFrameSize = 0;
            for(var frameIndex = 0; frameIndex < frames.length; frameIndex++) {
                var frameSize = frames[frameIndex].offsetWidth + frames[frameIndex].offsetHeight;
                var canAccessFrame = false;
                try {
                    frames[frameIndex].contentWindow.document.body;
                    canAccessFrame = true;
                }
                catch(eFrames) {
                    dbg(eFrames);
                }
                
                if(canAccessFrame && frameSize > bestFrameSize) {
                    bestFrame = frames[frameIndex];
                    bestFrameSize = frameSize;
                }
            }

            if(bestFrame) {
                var newBody = document.createElement('body');
                newBody.innerHTML = bestFrame.contentWindow.document.body.innerHTML;
                newBody.style.overflow = 'scroll';
                document.body = newBody;
                
                var frameset = document.getElementsByTagName('frameset')[0];
                if(frameset) frameset.parentNode.removeChild(frameset);
                    
                readability.frameHack = true;
            }
        }

        /* remove all scripts that are not readability */
        var scripts = document.getElementsByTagName('script');
        for(var i = scripts.length-1; i >= 0; i--)
        {
            if(typeof(scripts[i].src) == "undefined" || (scripts[i].src.indexOf('readability') == -1 && scripts[i].src.indexOf('typekit') == -1))
            {
                scripts[i].parentNode.removeChild(scripts[i]);          
            }
        }

        /* remove all stylesheets */
        for (var k=0;k < document.styleSheets.length; k++) {
            if (document.styleSheets[k].href !== null && document.styleSheets[k].href.lastIndexOf("readability") == -1) {
                document.styleSheets[k].disabled = true;
            }
        }

        /* Remove all style tags in head */
        var styleTags = document.getElementsByTagName("style");
        for (var st=0;st < styleTags.length; st++) {
            if (navigator.appName != "Microsoft Internet Explorer") {
                styleTags[st].textContent = ""; }
        }

        /* Turn all double br's into p's */
        document.body.innerHTML = document.body.innerHTML.replace(readability.regexps.replaceBrsRe, '</p><p>').replace(readability.regexps.replaceFontsRe, '<$1span>');
    },

    /**
     * Prepare the article node for display. Clean out any inline styles,
     * iframes, forms, strip extraneous <p> tags, etc.
     **/
    prepArticle: function (articleContent) {
        readability.cleanStyles(articleContent);
        readability.killBreaks(articleContent);

        readability.clean(articleContent, "form");
        readability.clean(articleContent, "object");
        readability.clean(articleContent, "h1");

        if(articleContent.getElementsByTagName('h2').length == 1) {
            readability.clean(articleContent, "h2"); }
        readability.clean(articleContent, "iframe");

        readability.cleanHeaders(articleContent);

        readability.cleanConditionally(articleContent, "table");
        readability.cleanConditionally(articleContent, "ul");
        readability.cleanConditionally(articleContent, "div");

        /* Remove extra paragraphs */
        var articleParagraphs = articleContent.getElementsByTagName('p');
        for(var i = articleParagraphs.length-1; i >= 0; i--) {
            var imgCount    = articleParagraphs[i].getElementsByTagName('img').length;
            var embedCount  = articleParagraphs[i].getElementsByTagName('embed').length;
            var objectCount = articleParagraphs[i].getElementsByTagName('object').length;
            
            if(imgCount === 0 && embedCount === 0 && objectCount === 0 && readability.getInnerText(articleParagraphs[i], false) == '') {
                articleParagraphs[i].parentNode.removeChild(articleParagraphs[i]);
            }
        }

        articleContent.innerHTML = articleContent.innerHTML.replace(/<br[^>]*>\s*<p/gi, '<p');
    },
    
    initializeNode: function (node) {
        node.readability = {"contentScore": 0};         

        switch(node.tagName) {
            case 'DIV':
                node.readability.contentScore += 5;
                break;

            case 'PRE':
            case 'TD':
            case 'BLOCKQUOTE':
                node.readability.contentScore += 3;
                break;
                
            case 'ADDRESS':
            case 'OL':
            case 'UL':
            case 'DL':
            case 'DD':
            case 'DT':
            case 'LI':
            case 'FORM':
                node.readability.contentScore -= 3;
                break;

            case 'H1':
            case 'H2':
            case 'H3':
            case 'H4':
            case 'H5':
            case 'H6':
            case 'TH':
                node.readability.contentScore -= 5;
                break;
        }

        node.readability.contentScore += readability.getClassWeight(node);
    },
    
    grabArticle: function () {
        var stripUnlikelyCandidates = readability.flagIsActive(readability.FLAG_STRIP_UNLIKELYS);

        var node = null;
        for(var nodeIndex = 0; (node = document.getElementsByTagName('*')[nodeIndex]); nodeIndex++) {
            if (stripUnlikelyCandidates) {
                var unlikelyMatchString = node.className + node.id;
                if (unlikelyMatchString.search(readability.regexps.unlikelyCandidatesRe) !== -1 &&
                    unlikelyMatchString.search(readability.regexps.okMaybeItsACandidateRe) == -1 &&
                    node.tagName !== "BODY") {
                  dbg("Removing unlikely candidate - " + unlikelyMatchString);
                  node.parentNode.removeChild(node);
                  nodeIndex--;
                  continue;
                }               
            }

            if (node.tagName === "DIV") {
                if (node.innerHTML.search(readability.regexps.divToPElementsRe) === -1) {
                    var newNode = document.createElement('p');
                    newNode.innerHTML = node.innerHTML;             
                    node.parentNode.replaceChild(newNode, node);
                    nodeIndex--;
                }
                else {
                    /* EXPERIMENTAL */
                    for(var i = 0, il = node.childNodes.length; i < il; i++) {
                        var childNode = node.childNodes[i];
                        if(childNode.nodeType == 3) { // Node.TEXT_NODE
                            dbg("replacing text node with a p tag with the same content.");
                            var p = document.createElement('p');
                            p.innerHTML = childNode.nodeValue;
                            p.style.display = 'inline';
                            p.className = 'readability-styled';
                            childNode.parentNode.replaceChild(p, childNode);
                        }
                    }
                }
            } 
        }

        var allParagraphs = document.getElementsByTagName("p");
        var candidates    = [];

        for (var pt=0; pt < allParagraphs.length; pt++) {
            var parentNode      = allParagraphs[pt].parentNode;
            var grandParentNode = parentNode.parentNode;
            var innerText       = readability.getInnerText(allParagraphs[pt]);

            if(innerText.length < 25) {
                continue; }

            if(typeof parentNode.readability == 'undefined') {
                readability.initializeNode(parentNode);
                candidates.push(parentNode);
            }

            if(typeof grandParentNode.readability == 'undefined') {
                readability.initializeNode(grandParentNode);
                candidates.push(grandParentNode);
            }

            var contentScore = 0;

            contentScore++;

            contentScore += innerText.split(',').length;
            
            contentScore += Math.min(Math.floor(innerText.length / 100), 3);
            
            parentNode.readability.contentScore += contentScore;
            grandParentNode.readability.contentScore += contentScore/2;
        }

        var topCandidate = null;
        for(var c=0, cl=candidates.length; c < cl; c++) {
            candidates[c].readability.contentScore = candidates[c].readability.contentScore * (1-readability.getLinkDensity(candidates[c]));

            if(!topCandidate || candidates[c].readability.contentScore > topCandidate.readability.contentScore) {
                topCandidate = candidates[c]; }
        }

        /**
         * Now that we have the top candidate, look through its siblings for content that might also be related.
         * Things like preambles, content split by ads that we removed, etc.
        **/
        var articleContent        = document.createElement("DIV");
            articleContent.id     = "readability-content";
        var siblingScoreThreshold = Math.max(10, topCandidate.readability.contentScore * 0.2);
        var siblingNodes          = topCandidate.parentNode.childNodes;
        for(var s=0, sl=siblingNodes.length; s < sl; s++) {
            var siblingNode = siblingNodes[s];
            var append      = false;

            if(siblingNode === topCandidate) {
                append = true;
            }
            
            if(typeof siblingNode.readability != 'undefined' && siblingNode.readability.contentScore >= siblingScoreThreshold) {
                append = true;
            }
            
            if(siblingNode.nodeName == "P") {
                var linkDensity = readability.getLinkDensity(siblingNode);
                var nodeContent = readability.getInnerText(siblingNode);
                var nodeLength  = nodeContent.length;
                
                if(nodeLength > 80 && linkDensity < 0.25) {
                    append = true;
                }
                else if(nodeLength < 80 && linkDensity === 0 && nodeContent.search(/\.( |$)/) !== -1) {
                    append = true;
                }
            }

            if(append) {
                var nodeToAppend = null;
                if(siblingNode.nodeName != "DIV" && siblingNode.nodeName != "P") {
                    nodeToAppend = document.createElement('div');
                    nodeToAppend.className = siblingNode.className;
                    nodeToAppend.id = siblignNode.id;
                    nodeToAppend.innerHTML = siblingNode.innerHTML;
                } else {
                    nodeToAppend = siblingNode;
                }

                articleContent.appendChild(nodeToAppend);
                s--;
                sl--;
            }
        }

        readability.prepArticle(articleContent);
        
        return articleContent;
    },
    
    getInnerText: function (e, normalizeSpaces) {
        var textContent    = "";

        normalizeSpaces = (typeof normalizeSpaces == 'undefined') ? true : normalizeSpaces;

        if (navigator.appName == "Microsoft Internet Explorer") {
            textContent = e.innerText.replace( readability.regexps.trimRe, "" ); }
        else {
            textContent = e.textContent.replace( readability.regexps.trimRe, "" ); }

        if(normalizeSpaces) {
            return textContent.replace( readability.regexps.normalizeRe, " "); }
        else {
            return textContent; }
    },

    getCharCount: function (e,s) {
        s = s || ",";
        return readability.getInnerText(e).split(s).length;
    },

    cleanStyles: function (e) {
        e = e || document;
        var cur = e.firstChild;

        if(!e) {
            return; }

        // Remove any root styles, if we're able.
        if(typeof e.removeAttribute == 'function' && e.className != 'readability-styled') {
            e.removeAttribute('style'); }

        // Go until there are no more child nodes
        while ( cur !== null ) {
            if ( cur.nodeType == 1 ) {
                // Remove style attribute(s) :
                if(cur.className != "readability-styled") {
                    cur.removeAttribute("style");                   
                }
                readability.cleanStyles( cur );
            }
            cur = cur.nextSibling;
        }           
    },
    
    getLinkDensity: function (e) {
        var links      = e.getElementsByTagName("a");
        var textLength = readability.getInnerText(e).length;
        var linkLength = 0;
        for(var i=0, il=links.length; i<il;i++)
        {
            linkLength += readability.getInnerText(links[i]).length;
        }       

        return linkLength / textLength;
    },
    
    getClassWeight: function (e) {
        if(!readability.flagIsActive(readability.FLAG_WEIGHT_CLASSES)) {
            return 0;
        }

        var weight = 0;

        if (e.className != "") {
            if(e.className.search(readability.regexps.negativeRe) !== -1) {
                weight -= 25; }

            if(e.className.search(readability.regexps.positiveRe) !== -1) {
                weight += 25; }
        }

        if (typeof(e.id) == 'string' && e.id != "") {
            if(e.id.search(readability.regexps.negativeRe) !== -1) {
                weight -= 25; }

            if(e.id.search(readability.regexps.positiveRe) !== -1) {
                weight += 25; }
        }

        return weight;
    },
    
    killBreaks: function (e) {
      e.innerHTML = e.innerHTML.replace(readability.regexps.killBreaksRe,'<br />');       
    },

    /* Clean a node of all elements of type "tag". Except youtube movies. */
    clean: function (e, tag) {
        var targetList = e.getElementsByTagName( tag );
        var isEmbed    = (tag == 'object' || tag == 'embed');
        
        for (var y=targetList.length-1; y >= 0; y--) {
            if(isEmbed) {
                var attributeValues = "";
                for (var i=0, il=targetList[y].attributes.length; i < il; i++) {
                    attributeValues += targetList[y].attributes[i].value + '|';
                }
                
                if (attributeValues.search(readability.regexps.videoRe) !== -1) {
                    continue;
                }

                if (targetList[y].innerHTML.search(readability.regexps.videoRe) !== -1) {
                    continue;
                }
                
            }

            targetList[y].parentNode.removeChild(targetList[y]);
        }
    },
    
    /* Clean an element of all tags of type "tag" based on content length, classnames, link density, number of images & embeds, etc. */
    cleanConditionally: function (e, tag) {
        var tagsList      = e.getElementsByTagName(tag);
        var curTagsLength = tagsList.length;

        for (var i=curTagsLength-1; i >= 0; i--) {
            var weight = readability.getClassWeight(tagsList[i]);
            var contentScore = (typeof tagsList[i].readability != 'undefined') ? tagsList[i].readability.contentScore : 0;
            
            if(weight+contentScore < 0) {
                tagsList[i].parentNode.removeChild(tagsList[i]);
            }
            else if (readability.getCharCount(tagsList[i],',') < 10) {
                var p      = tagsList[i].getElementsByTagName("p").length;
                var img    = tagsList[i].getElementsByTagName("img").length;
                var li     = tagsList[i].getElementsByTagName("li").length-100;
                var input  = tagsList[i].getElementsByTagName("input").length;

                var embedCount = 0;
                var embeds     = tagsList[i].getElementsByTagName("embed");
                for(var ei=0,il=embeds.length; ei < il; ei++) {
                    if (embeds[ei].src.search(readability.regexps.videoRe) == -1) {
                      embedCount++; 
                    }
                }

                var linkDensity   = readability.getLinkDensity(tagsList[i]);
                var contentLength = readability.getInnerText(tagsList[i]).length;
                var toRemove      = false;

                if ( img > p ) {
                    toRemove = true;
                } else if(li > p && tag != "ul" && tag != "ol") {
                    toRemove = true;
                } else if( input > Math.floor(p/3) ) {
                    toRemove = true; 
                } else if(contentLength < 25 && (img === 0 || img > 2) ) {
                    toRemove = true;
                } else if(weight < 25 && linkDensity > 0.2) {
                    toRemove = true;
                } else if(weight >= 25 && linkDensity > 0.5) {
                    toRemove = true;
                } else if((embedCount == 1 && contentLength < 75) || embedCount > 1) {
                    toRemove = true;
                }

                if(toRemove) {
                    tagsList[i].parentNode.removeChild(tagsList[i]);
                }
            }
        }
    },

    /* Clean out spurious headers from an Element. Checks things like classnames and link density. */
    cleanHeaders: function (e) {
        for (var headerIndex = 1; headerIndex < 7; headerIndex++) {
            var headers = e.getElementsByTagName('h' + headerIndex);
            for (var i=headers.length-1; i >=0; i--) {
                if (readability.getClassWeight(headers[i]) < 0 || readability.getLinkDensity(headers[i]) > 0.33) {
                    headers[i].parentNode.removeChild(headers[i]);
                }
            }
        }
    },
};

readability.init();
