Flox: Changelog
===============

version 0.5 - 2012-04-18
------------------------

* added 'Query' class for SQL-like entity retrieval
* added 'firstStartTime' to Analytics report
* changed 'onComplete' argument in 'loadScores' to 'Array', for consistency with Query class
* more robust error handling when service cache is corrupted

version 0.4.1 - 2012-03-14
--------------------------

* removed static save and refresh methods

version 0.4 - 2012-03-13
------------------------

* added 'Entity' class for storing arbitrary objects on the server
* added Entity permissions ('publicAccess' property)
* added 'Player' class for basic player management
* added Player authentication methods (GUEST, KEY, EMAIL)
* added 'Flox.flushLocalData'
* added SharedObject pooling for better performance
* added 'QueueEvent', dispatched on service queue processing
* added ETag handling
* now processing entity queue before any other request is executed

version 0.3 - 2012-10-31
------------------------

* added Leaderboards
* added 'Flox.reportAnalytics' property
* enhanded 'Flox.logError' method


version 0.2 - 2012-10-11
------------------------

* added event properties
* fixed small issues


version 0.1 - 2012-09-04
------------------------

* first public version
* analytics
