var Riak = require('riak-node'), db = new Riak.Client(8011);

// save only if absent
db.add = function(bucket, key, elem, callback) {
  db.get(bucket, key)(
    function(response, meta){},
    function(response, meta){
      db.save(bucket, key, elem)();
    }
  );
}

if (typeof module !== 'undefined') {
  module.exports = db;
}
