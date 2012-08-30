// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.utils.formatString;
    
    import flash.system.ApplicationDomain;
    import flash.system.Capabilities;
    import flash.system.Security;
    
    public class Flox
    {
        public static const VERSION:String = "0.1";
        public static const BASE_URL:String   = "https://www.flox.cc/api";
        
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
        }
        
        public static function shutdown():void
        {
            sGameSession.end();
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
        
        // properties
        
        public static function get gameID():String { return sGameID; }
        public static function get gameKey():String { return sGameKey; }
        public static function get gameVersion():String { return sGameVersion; }
    }
}