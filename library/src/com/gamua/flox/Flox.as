// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.utils.createUID;
    import com.gamua.flox.utils.formatString;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.net.SharedObject;
    import flash.net.registerClassAlias;
    import flash.system.Capabilities;
    import flash.utils.getDefinitionByName;
    
    /** The main class used to interact with the Flox cloud service.
     * 
     *  <p>Do not instantiate this class, but instead use the provided static methods.
     *  Here is a typical sample on how to integrate Flox in our game:</p>
     *  
     *  <p>Make this call right at the beginning:</p>
     *  <pre>
     *  Flox.init("my-game-id", "my-game-key", "1.0");</pre>
     *  
     *  <p>Log important information at run-time:</p>
     *  <pre>
     *  Flox.logInfo("Player {0} lost a life.", player);
     *  Flox.logWarning("Something fishy is going on!");
     *  Flox.logError("Hell just broke loose: {0}", error.message);</pre>
     *  
     *  <p>Events are displayed separately in the online interface. 
     *  Use a limited set of strings for event names and property values; otherwise, the 
     *  visualization of the data in the online interface will become useless quickly.</p>
     *  <pre>
     *  Flox.logEvent("GameStarted");
     *  Flox.logEvent("MenuChanged", { from: "MainMenu", to: "SettingsMenu" });</pre>
     */
    public class Flox
    {
        public static const VERSION:String  = "0.2";
        public static const BASE_URL:String = "https://www.flox.cc/api";
        
        private static var sGameID:String;
        private static var sGameKey:String;
        private static var sGameVersion:String;
        private static var sLanguage:String;
        private static var sRestService:RestService;
        private static var sPersistentData:SharedObject;
        private static var sMonitoringNativeApplicationEvents:Boolean;
        
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
            pause();
        }
        
        internal static function initWithBaseURL(
            gameID:String, gameKey:String, gameVersion:String, baseURL:String):void
        {
            registerClassAlias("GameSession", GameSession);
            registerClassAlias("Authentication", Authentication);
            
            sGameID = gameID;
            sGameKey = gameKey;
            sGameVersion = gameVersion;
            sLanguage = Capabilities.language;
            sRestService = new RestService(BASE_URL, gameID, gameKey);
            
            sPersistentData = SharedObject.getLocal("Flox." + gameID);
            sPersistentData.data.session = GameSession.start(gameID, gameVersion, session);
            
            if (sPersistentData.data.authentication == undefined)
                sPersistentData.data.authentication = new Authentication(createUID());
            
            monitorNativeApplicationEvents();
        }
        
        // logging
        
        /** Add a log of type 'info'. Pass parameters in .Net style ('{0}', '{1}', etc). */
        public static function logInfo(message:String, ...args):void
        {
            message = formatString(message, args);
            if (session) session.logInfo(message);
            trace("[Info]", message);
        }
        
        /** Add a log of type 'warning'. Pass parameters in .Net style ('{0}', '{1}', etc). */
        public static function logWarning(message:String, ...args):void
        {
            message = formatString(message, args);
            if (session) session.logWarning(message);
            trace("[Warning]", message);
        }
        
        /** Add a log of type 'error'. 
         *  
         *  @param error   either an instance of the 'Error' class, or a short string (e.g.
         *                 "FileNotFound"). Used to classify the error in the online interface.
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
                session.logError(errorObject.name, message, errorObject.getStackTrace());
                trace("[Error]", errorObject.name + ":", message); 
            }
            else
            {
                session.logError(error.toString(), message);
                trace("[Error]", message ? error + ": " + message : error); 
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
            trace("[Event]", properties === null ? name : name + ": " + JSON.stringify(properties));
        }
        
        // utils
        
        private static function pause():void
        {
            if (session) 
            {
                session.pause();
                sPersistentData.flush();
                sRestService.save();
            }
        }
        
        private static function monitorNativeApplicationEvents():void
        {
            if (!sMonitoringNativeApplicationEvents)
            {
                sMonitoringNativeApplicationEvents = true;
                
                try
                {
                    var nativeAppClass:Object = getDefinitionByName("flash.desktop::NativeApplication");
                    var nativeApp:EventDispatcher = nativeAppClass["nativeApplication"] as EventDispatcher;
                    
                    nativeApp.addEventListener(Event.ACTIVATE, function (e:Event):void 
                    {
                        logInfo("Game activated");
                        session.start(); 
                    });
                    
                    nativeApp.addEventListener(Event.DEACTIVATE, function (e:Event):void 
                    {
                        logInfo("Game deactivated");
                        pause(); 
                    });
                }
                catch (e:Error) {} // we're not running in AIR
            }
        }
        
        private static function get session():GameSession
        {
            return sPersistentData.data.session;
        }
        
        private static function get authentication():Authentication
        {
            return sPersistentData.data.authentication;
        }
        
        internal static function get service():RestService
        {
            return sRestService;
        }
        
        // properties
        
        /** The unique id of this game. */
        public static function get gameID():String { return sGameID; }
        
        /** The secret key of this game. */
        public static function get gameKey():String { return sGameKey; }
        
        /** The version of this game. */
        public static function get gameVersion():String { return sGameVersion; }
    }
}