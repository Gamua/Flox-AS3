// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.HttpMethod;
    import com.gamua.flox.utils.createUID;
    import com.gamua.flox.utils.execute;
    import com.gamua.flox.utils.formatString;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.net.SharedObject;
    import flash.net.registerClassAlias;
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
        public static const VERSION:String  = "0.3";
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
        
        /** @private */ 
        public function Flox() { throw new Error("This class cannot be instantiated."); }
        
        // initialization
        
        /** Initialize Flox with a certain game ID and key. Use the 'gameVersion' parameter
         *  to link the collected analytics to a certain game version. */  
        public static function init(gameID:String, gameKey:String, gameVersion:String="1.0"):void
        {
            initWithBaseURL(gameID, gameKey, gameVersion, BASE_URL);
        }
        
        /** Stop the Flox session. You don't have to do this manually in most cases. */
        public static function shutdown():void
        {
            if (!sInitialized) return;
            
            monitorNativeApplicationEvents(false);
            session.pause();
            
            sGameID = sGameKey = sGameVersion = null;
            sRestService = null;
            sPersistentData = null;
            sInitialized = false;
        }
        
        /** @private
         *  Initialize Flox with a custom base URL (useful for unit tests). */
        internal static function initWithBaseURL(
            gameID:String, gameKey:String, gameVersion:String, baseURL:String):void
        {
            if (sInitialized)
                throw new Error("Flox is already initialized!");
            
            registerClassAlias("GameSession", GameSession);
            registerClassAlias("Authentication", Authentication);
            monitorNativeApplicationEvents(true);
            
            sInitialized = true;
            sGameID = gameID;
            sGameKey = gameKey;
            sGameVersion = gameVersion;
            sRestService = new RestService(baseURL, gameID, gameKey);
            sPersistentData = SharedObject.getLocal("Flox." + gameID);
            
            if (localPlayer == null) playerLogin();
            
            sPersistentData.data.session = 
                GameSession.start(gameID, gameVersion, session, sReportAnalytics);
        }
        
        // player handling
        
        /** Log in a new player with the given authentication information. If you pass no
         *  parameters, a new guest will be logged in; the 'Flox.localPlayer' parameter will
         *  immediately reference that player.
         * 
         *  <p>Flox requires that there's always a player logged in. Thus, there is no 'logout'  
         *  method. If you want to remove the reference to the current player, just call  
         *  'playerLogin' again (without arguments). The previous player will then be replaced 
         *  by a new guest.</p> 
         *   
         *  @param onComplete: function onComplete(localPlayer:Player):void;
         *  @param onError:    function onError(error:String):void;
         */
        public static function playerLogin(
            authType:String="guest", authID:String=null, authToken:String=null,
            onComplete:Function=null, onError:Function=null):void
        {
            checkInitialized();
            clearCache();
            
            if (authType == AuthenticationType.GUEST)
            {
                var player:Player = new Player();
                player.authID = authID ? authID : createUID();
                sPersistentData.data.authToken = authToken ? authToken : createUID();
                sPersistentData.data.localPlayer = player;
                execute(onComplete, player);
            }
            else
            {
                throw new ArgumentError("Authentication type not supported: " + authType);
            }
        }
        
        // leaderboards
        
        /** Loads the scores of a certain leaderboard from the server. At the moment, you get
         *  a maximum of 50 scores per leaderboard and time scope. Each player (i.e. device
         *  installation) will be in the list only once.
         *  
         *  @param leaderboardID: the leaderboard ID you have defined in the Flox online interface.
         *  @param timescope:  the time range the leaderboard contains. The corresponding string
         *                     constants are defined in the "TimeScope" class. 
         *  @param onComplete: a callback with the form: 
         *                     <pre>onComplete(scores:Vector.&lt;Score&gt;):void;</pre>
         *  @param onError:    a callback with the form:
         *                     <pre>onError(error:String):void;</pre>
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
                            onRequestComplete, onError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                var scores:Vector.<Score> = new <Score>[];
                for each (var rawScore:Object in body as Array)
                {
                    scores.push(new Score(rawScore.playerName, rawScore.countryCode, 
                                          parseInt(rawScore.value), 
                                          DateUtil.parse(rawScore.createdAt)));
                }
                execute(onComplete, scores);
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
        
        /** Clears all locally cached data (entity cache, http service queue). */
        public static function clearCache():void
        {
            checkInitialized();
            sRestService.clearPersistentData();
        }
        
        // logging
        
        /** Add a log of type 'info'. Pass parameters in .Net style ('{0}', '{1}', etc). */
        public static function logInfo(message:String, ...args):void
        {
            checkInitialized();
            
            message = formatString(message, args);
            session.logInfo(message);
            log("[Info]", message);
        }
        
        /** Add a log of type 'warning'. Pass parameters in .Net style ('{0}', '{1}', etc). */
        public static function logWarning(message:String, ...args):void
        {
            checkInitialized();
            
            message = formatString(message, args);
            session.logWarning(message);
            log("[Warning]", message);
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
            checkInitialized();
            
            if (message) message = formatString(message, args);
            var errorObject:Error = error as Error;
            
            if (errorObject)
            {
                if (message == null) message = errorObject.message;
                session.logError(errorObject.name, message, errorObject.getStackTrace());
                log("[Error]", errorObject.name + ":", message); 
            }
            else
            {
                session.logError(error.toString(), message);
                log("[Error]", message ? error + ": " + message : error); 
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
            checkInitialized();
            
            if (session) session.logEvent(name, properties);
            log("[Event]", properties === null ? name : name + ": " + JSON.stringify(properties));
        }
        
        // utils
        
        private static function checkInitialized():void
        {
            if (!sInitialized) throw new Error("Call 'Flox.init()' before using any other method.");
        }
        
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
        }
        
        private static function onDeactivate(event:Event):void
        {
            logInfo("Game deactivated");
            session.pause();
            sPersistentData.flush();
            sRestService.save();
        }
        
        /** @private 
         *  The current game session / analytics object. */
        internal static function get session():GameSession
        {
            checkInitialized();
            return sPersistentData.data.session;
        }
        
        /** @private 
         *  The authentication data of the current player. */
        internal static function get authentication():Authentication
        {
            checkInitialized();
            
            if (sAuthentication == null) 
                sAuthentication = new Authentication();
            
            sAuthentication.playerID = localPlayer.id;
            sAuthentication.id = localPlayer.authID;
            sAuthentication.type = localPlayer.authType;
            sAuthentication.token = sPersistentData.data.authToken;
            
            return sAuthentication;
        }
        
        /** @private
         *  The rest service class used to communicate with the server. */
        internal static function get service():RestService
        {
            checkInitialized();
            return sRestService;
        }
        
        // properties
        
        /** The unique id of this game. */
        public static function get gameID():String { return sGameID; }
        
        /** The secret key of this game. */
        public static function get gameKey():String { return sGameKey; }
        
        /** The version of this game. */
        public static function get gameVersion():String { return sGameVersion; }
        
        /** The current local player. */
        public static function get localPlayer():Player
        {
            if (sPersistentData) return sPersistentData.data.localPlayer as Player;
            else return null;
        }
        
        /** Indicates if log methods should write their output to the console. @default true */
        public static function get traceLogs():Boolean { return sTraceLogs; }
        public static function set traceLogs(value:Boolean):void { sTraceLogs = value; }
        
        /** Indicates if analytics reports should be sent to the server. @default true */
        public static function get reportAnalytics():Boolean { return sReportAnalytics; }
        public static function set reportAnalytics(value:Boolean):void { sReportAnalytics = value; }
    }
}