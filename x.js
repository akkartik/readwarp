require.paths.unshift("/app/local/share/lib/js");
var sys = require('sys');
var fs = require('fs');
var Haml = require('haml');
var http = require('http'), twitter = http.createClient(80, 'api.twitter.com');
var Riak = require('riak-node'), db = new Riak.Client(8011);

var f = function(a, b) {
  return a+b;
}

sys.puts(Haml.render(fs.readFileSync('x.haml'),
                    {locals: {var1: 3, var2: 34, f: function(a, b){return a+b;} }}));

function twitter_request(url, callback) {
  var request = twitter.request('GET', url, {'host': 'api.twitter.com'});
  var data = '';
  request.addListener('response', function (response) {
    response.setEncoding('utf8');
    response.addListener('data', function (chunk) {
      data += chunk;
    });
    response.addListener('end', function () {
      callback(JSON.parse(data));
    });
  });
  request.end();
}

function twitter_statuses(username, callback) {
  twitter_request('/1/statuses/user_timeline/'+username+'.json?count=200',
                  callback);
}

function twitter_followee_ids(username, callback) {
  twitter_request('/1/friends/ids.json?screen_name='+username, callback);
}

function crawl_tweets(username, callback) {
  twitter_statuses(username, function(data) {
    for (var idx in data) {
//?       puts(JSON.stringify(data[idx]));
      if(callback) callback(data[idx]);
    }
  });
}

// save only if absent
db.add = function(bucket, key, elem, callback) {
  db.get(bucket, key)(
    function(response, meta){},
    function(response, meta){
      db.save(bucket, key, elem)();
    }
  );
}

crawl_tweets('akkartik', function(elem) {
  db.add('tweets', elem['id'], elem);
});

//? db.get('tweets')();
