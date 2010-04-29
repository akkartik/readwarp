var http = require('http'), twitter = http.createClient(80, 'api.twitter.com');

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

exports.crawl_tweets = function(username, callback) {
  twitter_statuses(username, function(data) {
    for (var idx in data) {
//?       puts(JSON.stringify(data[idx]));
      if(callback) callback(data[idx]);
    }
  });
}
