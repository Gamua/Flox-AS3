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
    import flash.system.ApplicationDomain;
    import flash.system.Capabilities;
    import flash.system.Security;
    import flash.utils.getDefinitionByName;
    
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
        
        public function Flox() { throw new Error("This class cannot be instantiated."); }
        
        // initialization
        
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
        
        public static function shutdown():void
        {
            pause();
        }
        
        // logging
        
        public static function logInfo(message:String, ...args):void
        {
            message = formatString(message, args);
            sGameSession.logInfo(message);
            trace("[Info]", message);
        }
        
        public static function logWarning(message:String, ...args):void
        {
            message = formatString(message, args);
            sGameSession.logWarning(message);
            trace("[Warning]", message);
        }
        
        public static function logError(message:String, ...args):void
        {
            message = formatString(message, args);
            sGameSession.logError(message);
            trace("[Error]", message);
        }
        
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