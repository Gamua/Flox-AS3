Flox: Changelog
===============

version 1.1 - 2013-11-14
------------------------

* added 'friends' scope for leaderboards (just pass the playerIDs you're interested in)
* added 'Flox.useSecureConnection' property
* changed leaderboard REST API

version 1.0.2 - 2013-11-04
--------------------------

* changed the maximum number of scores returned by 'Flox.loadScores' from 50 to 200
* several updates of the API documentation

version 1.0.1 - 2013-10-11
--------------------------

* added missing 'keep-as3-metadata' options to SWC file
* added information about 'Date'-type support into Entity API documentation

version 1.0 - 2013-10-02
------------------------

* added 'orderBy' property to Query
* added 'constraints' property to Query
* added 'SHA256' utility class
* added optional 'length' and 'seed' arguments to 'createUID' function
* made 'Base64' utility class public
* made cache & queue more reliable by manually flushing shared objects in memory on DEACTIVATE
* now trimming redundant put-requests from request queue

version 0.9 - 2013-08-22
------------------------

* If a game is suspended for more than 15 minutes, a new session will be started when the
  application is re-activated. This makes analytics much more accurate, especially on Android.
* SWC file now contains ASDoc information

version 0.8 - 2013-08-05
------------------------

* now enforcing that 'Flox.playerClass' points to class that extends Player
* refreshing guest players now works even if the guest has not yet been saved at the server
* optimized overall performance and removed temporary object creations in Base64 class

version 0.7.1 - 2013-07-23
--------------------------

* now updating 'createdAt' and 'updatedAt' on Entities with data from server
* added some API documentation updates

version 0.7 - 2013-06-26
------------------------

* added optional [NonSerialized] meta data for entity properties
* preventing backup of shared objects on iCloud for iOS

version 0.6 - 2013-06-04
------------------------

* added serialization of public members in Entities
* added some more API documentation
* prohibiting change of certain properties in the Player class

version 0.5 - 2013-04-18
------------------------

* added 'Query' class for SQL-like entity retrieval
* added 'firstStartTime' to Analytics report
* changed 'onComplete' argument in 'loadScores' to 'Array', for consistency with Query class
* more robust error handling when service cache is corrupted

version 0.4.1 - 2013-03-14
--------------------------

* removed static save and refresh methods

version 0.4 - 2013-03-13
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
