load('/usr/local/src/lodash/lodash.min.js');

var languages = [];
var language_count = [];

// find unique languages
db.users.find({},{_id:0,languages:1}).forEach(function(user) {
  languages = _.union(languages, user.languages);
  print(user.languages);
});


_.forEach(languages, function(language) {
  var helpers_count = db.users.count( { languages: { $in: [ language ] }, role:"helper" } );
  var blind_count = db.users.count( { languages: { $in: [ language ] }, role:"blind" } );
  print(language);
  print(helpers_count);
  cnt = { helper_count:helpers_count, language:language, blind_count:blind_count};
  language_count.push(cnt);
});

language_count
_.sortBy(language_count, function(count) { return count.helper_count });

