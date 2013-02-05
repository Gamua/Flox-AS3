// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.HttpMethod;
    import com.gamua.flox.utils.createUID;
    import com.gamua.flox.utils.execute;
    import com.gamua.flox.utils.formatString;
    import com.gamua.flox.utils.registerClassAlias;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.net.SharedObject;
    import flash.utils.getDefinitionByName;
    
    /** The main class used to interact with the Flox cloud service.
     * 
     *  <p>Do not instantiate this class, but instead use the provided static methods. 
     *  Right at the beginning, you have to initialize Flox:</p>
     *  <pre>
     *  Flox.init("my-game-id", "my-game-key", "1.0");</pre>
     *  
     *  <p><strong>Logs</strong></p> 
     * 
     *  <p>You can use Flox to log important information at run-time. By logging relevant 
     *  information of a game session, you will be able to understand what has happened in 
     *  a specific session, which is a great help in case of an error.</p>
     *  <pre>
     *  Flox.logInfo("Player {0} lost a life.", player);
     *  Flox.logWarning("Something fishy is going on!");
     *  Flox.logError(error);</pre>
     *
     *  <p><strong>Events</strong></p> 
     *   
     *  <p>Events are displayed separately in the online interface. They are a great way to get
     *  feedback about the usage of a game.
     *  Use a limited set of strings for event names and property values, though. Otherwise, 
     *  the visualization of the data in the online interface will become useless quickly.</p>
     *  <pre>
     *  Flox.logEvent("GameStarted");
     *  Flox.logEvent("MenuChanged", { from: "MainMenu", to: "SettingsMenu" });</pre>
     * 
     *  <p><strong>Leaderboards</strong></p>
     *  
     *  <p>It's easy to send and retrieve scores to the Flox server. First, you have to set up 
     *  a leaderboard in the online interface; the ID of the leaderboard is then used to identify
     *  it on the client. When retrieving scores, you can choose between different 'TimeScopes'.</p>
     *  <pre>
     *  Flox.postScore("default", 999, "Johnny");
     *  Flox.loadScores("default", TimeScope.ALL_TIME, 
     *      function onComplete(scores:Vector.&lt;Score&gt;):void
     *      {
     *          trace("retrieved " + scores.length + " scores");
     *      },
     *      function onError(error:String):void
     *      {
     *          trace("error loading scores: " + error);
     *      });</pre>
     *  
     *  @see TimeScope
     * 
     */
    public class Flox
    {
        /** The current version of the Flox library. */
        public static const VERSION:String  = "0.3";
        
        /** The base URL of the Flox REST API. */
        public static const BASE_URL:String = "https://www.flox.cc/api";
        
        private static var sGameID:String;
        private static var sGameKey:String;
        private static var sGameVersion:String;
        private static var sRestService:RestService;
        private static var sPersistentData:SharedObject;
        private static var sAuthentication:Authentication;
        private static var sInitialized:Boolean = false;
        
        private static var sTraceLogs:Boolean = true;
        private static var sReportAnalytics:Boolean = true;
        private static var sPlayerClass:Class = Player;
        
        /** @private */ 
        public function Flox() { throw new Error("This class cannot be instantiated."); }
        
        // initialization
        
        /** Initialize Flox with a certain game ID and key. Use the 'gameVersion' parameter
         *  to link the collected analytics to a certain game version. */  
        public static function init(gameID:String, gameKey:String, gameVersion:String="1.0"):void
        {
            initWithBaseURL(gameID, gameKey, gameVersion, BASE_URL);
        }
        
        /** @private
         *  Initialize Flox with a custom base URL (useful for unit tests). */
        internal static function initWithBaseURL(
            gameID:String, gameKey:String, gameVersion:String, baseURL:String):void
        {
            if (sInitialized)
                throw new Error("Flox is already initialized!");
            
            registerClassAlias(GameSession);
            registerClassAlias(Authentication);
            registerClassAlias(Player);

            monitorNativeApplicationEvents(true);
            SharedObjectPool.startAutoCleanup();
            
            sInitialized = true;
            sGameID = gameID;
            sGameKey = gameKey;
            sGameVersion = gameVersion;
            
            if (sRestService == null || sRestService.url != baseURL ||
                sRestService.gameID != gameID || sRestService.gameKey != gameKey)
            {
                sRestService = new RestService(baseURL, gameID, gameKey);
                sPersistentData = SharedObject.getLocal("Flox." + gameID);
            }
            
            if (Player.local == null) Player.login();
            
            sRestService.alwaysFail = false;
            sPersistentData.data.session = 
                GameSession.start(gameID, gameVersion, session, sReportAnalytics);
        }
        
        /** Stop the Flox session. You don't have to do this manually in most cases. */
        public static function shutdown():void
        {
            if (!sInitialized) return;
            
            monitorNativeApplicationEvents(false);
            session.pause();
            flushLocalData();
            
            sGameID = sGameKey = sGameVersion = null;
            sInitialized = false;
            
            // those may be reused (useful mainly for unit tests)
            // sRestService = null;
            // sPersistentData = null;
        }
        
        // leaderboards
        
        /** Loads the scores of a certain leaderboard from the server. At the moment, you get
         *  a maximum of 50 scores per leaderboard and time scope. Each player (i.e. device
         *  installation) will be in the list only once.
         *  
         *  <p>Note that when the server cannot be reached (e.g. because the player is offline)
         *  the 'onError' callback contains the scores that Flox cached from the last request
         *  (if available, otherwise the parameter is null).</p>
         *  
         *  @param leaderboardID: the leaderboard ID you have defined in the Flox online interface.
         *  @param timescope:  the time range the leaderboard contains. The corresponding string
         *                     constants are defined in the "TimeScope" class. 
         *  @param onComplete: a callback with the form: 
         *                     <pre>onComplete(scores:Vector.&lt;Score&gt;):void;</pre>
         *  @param onError:    a callback with the form:
         *                     <pre>onError(error:String, cachedScores:Vector.&lt;Score&gt;):void;</pre>
         */
        public static function loadScores(leaderboardID:String, timescope:String,
                                          onComplete:Function, onError:Function):void
        {
            checkInitialized();
            
            var query:Object = { 
                leaderboardId: leaderboardID,
                timeScope: timescope,
                limit: 50,
                offset: 0
            };
            
            service.request(HttpMethod.GET, ".score", { q: JSON.stringify(query) },
                            onRequestComplete, onRequestError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                execute(onComplete, createScoreVector(body as Array));
            }
            
            function onRequestError(error:String, httpStatus:int, cachedBody:Object):void
            {
                execute(onError, error, createScoreVector(cachedBody as Array)); 
            }
            
            function createScoreVector(rawScores:Array):Vector.<Score>
            {
                if (rawScores == null) return null;
                else
                {
                    var scores:Vector.<Score> = new <Score>[];
                    for each (var rawScore:Object in rawScores)
                        scores.push(new Score(rawScore.playerName, rawScore.countryCode, 
                            parseInt(rawScore.value), 
                            DateUtil.parse(rawScore.createdAt)));
                    return scores;
                }
            }
        }
        
        /** Posts a score to a certain leaderboard. Beware that only the top score of a player 
         *  (currently: a game installation) will appear on the leaderboard. */
        public static function postScore(leaderboardID:String, score:int, playerName:String):void
        {
            checkInitialized();
            
            var data:Object = { leaderboardId: leaderboardID, playerName: playerName, value:score };
            service.requestQueued(HttpMethod.POST, ".score", data);
        }
        
        // misc
        
        /** Clears the request queue. */
        public static function clearQueue():void
        {
            checkInitialized();
            sRestService.clearQueue();
        }
        
        /** Clears the service cache (containing e.g. previously fetched entities or scores). */
        public static function clearCache():void
        {
            checkInitialized();
            sRestService.clearCache();
        }
        
        /** Flushes all locally cached data to disk (entity cache, http service queue). */
        public static function flushLocalData(minDiskSpace:int=0):void
        {
            checkInitialized();
            sPersistentData.flush(minDiskSpace);
            sRestService.flush();
        }
        
        // logging
        
        /** Add a log of type 'info'. Pass parameters in .Net style ('{0}', '{1}', etc). */
        public static function logInfo(message:String, ...args):void
        {
            message = formatString(message, args);
            log("[Info]", message);
            
            if (sInitialized)
                session.logInfo(message);
        }
        
        /** Add a log of type 'warning'. Pass parameters in .Net style ('{0}', '{1}', etc). */
        public static function logWarning(message:String, ...args):void
        {
            message = formatString(message, args);
            log("[Warning]", message);
            
            if (sInitialized)
                session.logWarning(message);
        }
        
        /** Add a log of type 'error'. 
         *  
         *  @param error   either an instance of the 'Error' class, or a short string (e.g.
         *                 'FileNotFound'). Used to classify the error in the online interface.
         *  @param message additional information about the error. Accepts parameters in .Net 
         *                 style ('{0}', '{1}', etc). If the first parameter is an 'Error' and 
         *                 you don't pass a message, 'error.message' will be logged instead.
         */
        public static function logError(error:Object, message:String=null, ...args):void
        {
            if (message) message = formatString(message, args);
            var errorObject:Error = error as Error;
            
            if (errorObject)
            {
                if (message == null) message = errorObject.message;
                log("[Error]", errorObject.name + ":", message);
                
                if (sInitialized) 
                    session.logError(errorObject.name, message, errorObject.getStackTrace());
            }
            else
            {
                log("[Error]", message ? error + ": " + message : error);
                
                if (sInitialized)
                    session.logError(error.toString(), message);
            }
        }
        
        /** Add a log of type 'event'. Events are displayed separately in the online interface.
         *  Limit yourself to a predefined set of strings!
         *  
         *  @param properties: An optional dictionary with additional information about the event.
         *                     Again, use only a small set of different values, otherwise the 
         *                     visualization of the data will become useless quickly. */
        public static function logEvent(name:String, properties:Object=null):void
        {
            if (session) session.logEvent(name, properties);
            log("[Event]", properties === null ? name : name + ": " + JSON.stringify(properties));
        }
        
        // request queue
        
        /** Starts processing the request queue. The request queue is mainly used by the 'queued'
         *  variants of the Entity access methods. Normally, you don't have to call this method
         *  manually: it will be processed whenever you make a request on the server or add
         *  something to the queue. */
        public static function processQueue():void
        {
            checkInitialized();
            sRestService.processQueue();
        }
        
        /** Registers an event listener so that you are notified when one of Flox' events
         *  is dispatched (currently, there's only one event type: 'QUEUE_PROCESSED'). */ 
        public static function addEventListener(type:String, listener:Function, priority:int=0, 
                                                useWeakReference:Boolean=false):void
        {
            checkInitialized();
            sRestService.addEventListener(type, listener, false, priority, useWeakReference);
        }
        
        /** Unregisters an event listener that was added before. */
        public static function removeEventListener(type:String, listener:Function):void
        {
            if (sInitialized) sRestService.removeEventListener(type, listener);
        }
        
        // utils
        
        private static function log(...args):void
        {
            if (sTraceLogs) trace(args.join(" "));
        }
        
        private static function monitorNativeApplicationEvents(enable:Boolean):void
        {
            try
            {
                var nativeAppClass:Object = getDefinitionByName("flash.desktop::NativeApplication");
                var nativeApp:EventDispatcher = nativeAppClass["nativeApplication"] as EventDispatcher;
                
                if (enable)
                {
                    nativeApp.addEventListener(Event.ACTIVATE, onActivate, false, 0, true);
                    nativeApp.addEventListener(Event.DEACTIVATE, onDeactivate, false, 0, true);
                }
                else
                {
                    nativeApp.removeEventListener(Event.ACTIVATE, onActivate);
                    nativeApp.removeEventListener(Event.ACTIVATE, onDeactivate);
                }
            }
            catch (e:Error) {} // we're not running in AIR
        }
        
        private static function onActivate(event:Event):void
        {
            logInfo("Game activated");
            session.start();
            processQueue();
        }
        
        private static function onDeactivate(event:Event):void
        {
            logInfo("Game deactivated");
            session.pause();
            flushLocalData();
        }
        
        /** @private Checks if Flox was already initialized, and throws an Error if it wasn't. */
        internal static function checkInitialized():void
        {
            if (!sInitialized) throw new Error("Call 'Flox.init()' before using any other method.");
        }
        
        /** @private 
         *  The current game session / analytics object. */
        internal static function get session():GameSession
        {
            return sPersistentData ? sPersistentData.data.session as GameSession : null;
        }
        
        /** @private
         *  The rest service class used to communicate with the server. */
        internal static function get service():RestService
        {
            checkInitialized();
            return sRestService;
        }
        
        /** @private
         *  The current local player, persistent through a shared object. */
        internal static function get localPlayer():Player
        {
            return sPersistentData ? sPersistentData.data.localPlayer as sPlayerClass : null;
        }
        
        internal static function set localPlayer(value:Player):void
        {
            sPersistentData.data.localPlayer = value;
        }
        
        /** @private
         *  The current authentication, persistent through a shared object. */
        internal static function get authentication():Authentication
        {
            return sPersistentData ? sPersistentData.data.authentication as Authentication : null;
        }
        
        internal static function set authentication(value:Authentication):void
        {
            sPersistentData.data.authentication = value;
        }
        
        // properties
        
        /** The unique id of this game. */
        public static function get gameID():String { return sGameID; }
        
        /** The secret key of this game. */
        public static function get gameKey():String { return sGameKey; }
        
        /** The version of this game. */
        public static function get gameVersion():String { return sGameVersion; }
        
        /** Indicates if log methods should write their output to the console. @default true */
        public static function get traceLogs():Boolean { return sTraceLogs; }
        public static function set traceLogs(value:Boolean):void { sTraceLogs = value; }
        
        /** Indicates if analytics reports should be sent to the server. @default true */
        public static function get reportAnalytics():Boolean { return sReportAnalytics; }
        public static function set reportAnalytics(value:Boolean):void { sReportAnalytics = value; }
        
        /** Returns a unique identifier for the installation, i.e. when the
         *  app is deleted or the Flash cookies are lost, the id will change. */
        public static function get installationID():String
        {
            checkInitialized();
            
            var id:String = sPersistentData.data.installationID;
            if (id == null)
            {
                id = createUID();
                sPersistentData.data.installationID = id;
            }
            
            return id;
        }
        
        /** The class that is used for Flox player entities; needs to be a subclass of 'Player'.
         *  If you want to store additional information with your player entity, create a subclass
         *  of 'Player' and add the properties you need; then inform Flox about it by assigning
         *  the class here. Beware: this method has to be called BEFORE initializing Flox. */
        public static function get playerClass():Class { return sPlayerClass; }
        public static function set playerClass(value:Class):void
        {
            if (sInitialized) 
                throw new Error("The Player class needs to be set BEFORE calling 'Flox.init'.");
            else if (value == null)
                throw new Error("The Player class must not be 'null'");
            else
            {
                sPlayerClass = value;
                registerClassAlias(value);
            }
        }
    }
}