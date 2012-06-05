package com.gamua.flox
{
    import com.gamua.flox.utils.formatString;
    
    public class Flox
    {
        public static const VERSION:String = "1.0";
        
        private static const PLAYER_STORE:String = "Flox.localPlayer";
        private static const BASE_URL:String = "http://www.flox.cc/api";
        
        private static var sGameID:String;
        private static var sGameKey:String;
        
        public function Flox() { throw new Error("This class cannot be instantiated."); }
        
        // initialization
        
        public static function init(gameID:String, gameKey:String):void
        {
            HttpManager.init(BASE_URL);
            
            sGameID = gameID;
            sGameKey = gameKey;
        }
        
        public static function shutdown():void
        {
            sGameID = "";
            sGameKey = "";
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
        public static function loadLeaderboard(leaderboardID:String, timescope:String,
                                               onComplete:Function=null, onError:Function=null):void
        {
            Leaderboard.load(sGameID, leaderboardID, timescope, onComplete, onError);
        }
        
        public static function postScore(leaderboardID:String, score:int, playerName:String=null):void
        {
            Leaderboard.postScore(sGameID, leaderboardID, score, localPlayer.id, 
                                  (playerName ? playerName : localPlayer.name), 
                                  sGameKey);
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
        
        public static function get localPlayer():Player
        {
            if (PersistentStore.get(PLAYER_STORE) == null)
                PersistentStore.set(PLAYER_STORE, new Player());
            
            return PersistentStore.get(PLAYER_STORE) as Player;
        }
        
        public static function playerLogin(playerID:String):void 
        { 
            // TODO 
        }
        
        public static function playerLogout():void 
        {
            // TODO
        }
        
        // TODO: config, stuff store
        
        // properties
        
        public static function get gameID():String { return sGameID; }
        public static function get gameKey():String { return sGameKey; }
    }
}