load('/usr/local/src/lodash/lodash.min.js');

var languages = []

db.users.find({},{_id:0,languages:1}).forEach(function(user) {
languages = _.union(languages, user.languages);
print(user.languages);
});


_.forEach(languages, function(language) {
  var helpers_count = db.users.count( { languages: { $in: [ language ] }, role:"helper" } )
  print(language);
  print(helpers_count);
});
