package com.gamua.flox
{
    import com.gamua.flox.utils.formatString;
    
    import flash.events.Event;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestHeader;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.net.registerClassAlias;
    import flash.utils.ByteArray;

    public class Flox
    {
        public static const VERSION:String = "1.0";
        
        private static var sBaseUrl:String;
        private static var sGameID:String;
        private static var sGameKey:String;
        
        public function Flox() { throw new Error("This class cannot be instantiated."); }
        
        // initialization
        
        public static function init(gameID:String, gameKey:String):void
        {
            HttpManager.init();
            
            sGameID = gameID;
            sGameKey = gameKey;
            sBaseUrl = "http://www.flox.cc/api/games/" + gameID + "/";
                     //"http://192.168.11.132:8000/api/games/" + gameID + "/";
        }
        
        public static function shutdown():void
        {
            sGameID = "";
            sGameKey = "";
            sBaseUrl = "";
        }
        
        // analytics
        
        public static function logInfo(text:String, ...args):void
        {
            trace("[Info] " + formatString(text, args));
        }
        
        public static function logWarning(text:String, ...args):void
        {
            trace("[Warning] " + formatString(text, args));
        }
        
        public static function logError(error:Error, text:String, ...args):void
        {
            trace("[Error] " + formatString(text, args));
        }
        
        public static function logEvent(type:String):void
        {
            trace("[Event] " + type);
        }
        
        // leader board
        
        /** function(board:Leaderboard); */
        public static function loadLeaderboard(id:String, timescope:String,
                                               onComplete:Function=null, onError:Function=null):void
        {
            Leaderboard.load(id, timescope, onComplete, onError);
        }
        
        public static function postScore(leaderboardName:String, value:int, playerName:String=null):void
        {
            
        }
        
        // achievements
        /*
        public static function loadAchievements(onComplete:Function, onError:Function):void; // function(achievements:Vector.<Achievement>)
        
        public static function setAchievementProgress(id:String, value:Number):void;
        public static function raiseAchievementProgress(id:String, delta:Number):void;
        
        public static function get onAchievementProgress():Function;
        public static function set onAchievementProgress(value:Function):void; // function(achievement:Achievement, delta:Number)
        */
        
        // i18n
        /*
        public static function get language():String; // default set automatically
        public static function set language(value:String):void;
        
        public static function loadLocalizations(onComplete:Function, onError:Function):void; // function()
        */
        
        public static function localize(key:String, deflt:String=null, ...args):String
        {
            return deflt ? deflt : key;
        }
        
        // not in v1: player management
        /*
        // returns a persistant local player.
        public static function get defaultLocalPlayer():Player;
        
        public static function playerLogin(playerID:String):void {}
        public static function playerLogout():void {}
        */
        
        // TODO: config, stuff store
        
        // properties
        
        public static function get gameID():String { return sGameID; }
        public static function get gameKey():String { return sGameKey; }
        
        internal static function get baseUrl():String { return sBaseUrl; }
        internal static function createUrl(...rest):String
        {
            return sBaseUrl + rest.join("/");
        }
    }
}