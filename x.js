require.paths.unshift("/app/local/share/lib/js");
var sys = require('sys');
var fs = require('fs');
var Haml = require('haml');
var tw = require('./twitter');
var db = require('./db');

var f = function(a, b) {
  return a+b;
}

sys.puts(Haml.render(fs.readFileSync('x.haml'),
                    {locals: {var1: 3, var2: 34, f: function(a, b){return a+b;} }}));

tw.crawl_tweets('akkartik', function(elem) {
  db.add('tweets', elem['id'], elem);
});
