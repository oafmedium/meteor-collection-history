Package.describe({
  name: 'oaf:collection-history',
  summary: 'Enables logging of document changes on collections',
  version: '0.1.2',
  git: 'https://github.com/oafmedium/meteor-collection-history/'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0.2.1');
  api.use([
    'coffeescript',
    'mongo',
    'matb33:collection-hooks@0.7.9'
  ]);
  
  api.addFiles(['collection-history.coffee']);
  api.export('CollectionHistory');
});
