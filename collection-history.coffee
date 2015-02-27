class CollectionHistory
  @_collection: new Mongo.Collection 'collection-history'

  @_addHooks: (collection, options) ->
    defaultOptions =
      log:
        insert: true
        update: true
        remove: true
      fields: null
      omitFields: null

    options = _.extend defaultOptions, options

    if options.fields? and options.omitFields?
      throw new Error "[CollectionHistory] you cannot specify fields and omitFields!"

    ['insert','update','remove'].forEach (type) ->
      return unless options.log[type]
      collection.after[type] (userId, doc, fieldNames, modifier, options) ->
        state =
          type: type
          collection: collection._name
          documentId: doc._id
          userId: userId
          date: new Date()

        switch type
          when 'insert'
            state.previous = {}
            state.current = doc
          when 'update'
            state.previous = @previous
            state.current = doc
          when 'remove'
            state.previous = doc
            state.current = {}

        CollectionHistory._createState options, state

  @_createState: (options, doc) ->
    if options?.fields?
      doc.previous = _.pick doc.previous, options.fields
      doc.current = _.pick doc.current, options.fields
    if options?.omitFields?
      doc.previous = _.omit doc.previous, options.omitFields
      doc.current = _.omit doc.current, options.omitFields

    doc.changes = CollectionHistory._computeChanges doc.previous, doc.current
    CollectionHistory._collection.insert _.omit(doc, ['previous', 'current']) if doc.changes? and doc.changes.length > 0

  @_computeChanges: (previous, current) ->
    propertyChanges = []
    objectGraphPath = []
    matcher = (a, b) ->
      if a?.constructor == Object
        for property of _.extend {}, a, b
          objectGraphPath.push '.' + property
          if not a[property]? or a[property].constructor != Function
            matcher a[property], b[property]
          objectGraphPath.pop()
      else if not a? or a.constructor != Function
        unless _.isEqual a, b
          key = objectGraphPath.join('')
          key = key.slice 1 if key.charAt(0) is '.'
          propertyChanges.push
            'key': key
            'old': a
            'new': b
    matcher previous, current
    return propertyChanges




if Mongo?.Collection?
  Mongo.Collection.prototype.logHistory = (options) ->
    CollectionHistory._addHooks @, options if Meteor.isServer
else
  Meteor.Collection.prototype.logHistory = (options) ->
    CollectionHistory._addHooks @, options if Meteor.isServer
