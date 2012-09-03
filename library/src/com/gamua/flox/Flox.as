// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.utils.formatString;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
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
     *  Use a limited set of strings as event names.</p>
     *  <pre>
     *  Flox.logEvent("GameStarted");</pre>
     */
    public class Flox
    {
        public static const VERSION:String  = "0.1";
        public static const BASE_URL:String = "https://www.flox.cc/api";
        
        private static var sGameID:String;
        private static var sGameKey:String;
        private static var sGameVersion:String;
        private static var sLanguage:String;
        private static var sRestService:RestService;
        private static var sGameSession:GameSession;
        
        /** @private */ 
        public function Flox() { throw new Error("This class cannot be instantiated."); }
        
        // initialization
        
        /** Initialize Flox with a certain game ID and key. Use the 'gameVersion' parameter
         *  to link the collected analytics to a certain game version. */  
        public static function init(gameID:String, gameKey:String, gameVersion:String="1.0"):void
        {
            sGameID = gameID;
            sGameKey = gameKey;
            sGameVersion = gameVersion;
            sLanguage = Capabilities.language;
            sRestService = new RestService(BASE_URL, gameID, gameKey);
            sGameSession = GameSession.start(sRestService, gameVersion);
            
            monitorNativeApplicationEvents();
        }
        
        /** Stop the Flox session. You don't have to do this manually in most cases. */
        public static function shutdown():void
        {
            pause();
        }
        
        // logging
        
        /** Add a log of type 'info'. Pass paremeters in .Net style ('{0}', '{1}', etc.). */
        public static function logInfo(message:String, ...args):void
        {
            message = formatString(message, args);
            sGameSession.logInfo(message);
            trace("[Info]", message);
        }
        
        /** Add a log of type 'warning'. Pass paremeters in .Net style ('{0}', '{1}', etc.). */
        public static function logWarning(message:String, ...args):void
        {
            message = formatString(message, args);
            sGameSession.logWarning(message);
            trace("[Warning]", message);
        }
        
        /** Add a log of type 'error'. Pass paremeters in .Net style ('{0}', '{1}', etc.). */
        public static function logError(message:String, ...args):void
        {
            message = formatString(message, args);
            sGameSession.logError(message);
            trace("[Error]", message);
        }
        
        /** Add a log of type 'event'. Events are displayed separately in the online interface.
         *  Limit yourself to a predefined set of strings! */ 
        public static function logEvent(name:String):void
        {
            sGameSession.logEvent(name);
            trace("[Event]", name);
        }
        
        // utils
        
        private static function pause():void
        {
            sGameSession.pause();
            sGameSession.save();
            sRestService.save();
        }
        
        private static function monitorNativeApplicationEvents():void
        {
            try
            {
                var nativeAppClass:Object = getDefinitionByName("flash.desktop::NativeApplication");
                var nativeApp:EventDispatcher = nativeAppClass["nativeApplication"] as EventDispatcher;
                
                nativeApp.addEventListener(Event.ACTIVATE, function (e:Event):void 
                {
                    logInfo("Game activated");
                    sGameSession.start(); 
                });
                
                nativeApp.addEventListener(Event.DEACTIVATE, function (e:Event):void 
                {
                    logInfo("Game deactivated");
                    pause(); 
                });
            }
            catch (e:Error) {} // we're not running in AIR
        }
        
        // properties
        
        public static function get gameID():String { return sGameID; }
        public static function get gameKey():String { return sGameKey; }
        public static function get gameVersion():String { return sGameVersion; }
    }
}