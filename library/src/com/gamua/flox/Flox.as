package com.gamua.flox
{
    import com.gamua.flox.utils.formatString;
    import com.gamua.flox.utils.registerClass;
    
    import flash.system.Capabilities;
    
    public class Flox
    {
        public static const VERSION:String = "1.0";
        
        private static const PLAYER_STORE:String = "Flox.localPlayer";
        private static const BASE_URL:String = "http://www.flox.cc/api";
        
        private static var sGameID:String;
        private static var sGameKey:String;
        private static var sGameVersion:String;
        private static var sLanguage:String;
        
        public function Flox() { throw new Error("This class cannot be instantiated."); }
        
        // initialization
        
        public static function init(gameID:String, gameKey:String, gameVersion:String="1.0"):void
        {
            sGameID = gameID;
            sGameKey = gameKey;
            sGameVersion = gameVersion;
            sLanguage = Capabilities.language;
            
            registerClass(Player);
            HttpManager.init(BASE_URL);
            Analytics.startSession(gameID, gameKey, gameVersion);
        }
        
        public static function shutdown():void
        {
            sGameID = sGameKey = sGameVersion = "";
        }
        
        // analytics
        
        public static function logInfo(message:String, ...args):void
        {
            message = formatString(message, args);
            Analytics.logInfo(message);
            trace("[Info]", message);
        }
        
        public static function logWarning(message:String, ...args):void
        {
            message = formatString(message, args);
            Analytics.logWarning(message);
            trace("[Warning]", message);
        }
        
        public static function logError(message:String, ...args):void
        {
            message = formatString(message, args);
            Analytics.logError(message);
            trace("[Error]", message);
        }
        
        public static function logEvent(name:String):void
        {
            Analytics.logEvent(name);
            trace("[Event]", name);
        }
        
        // leader board
        
        /** function(board:Leaderboard); */
        public static function loadLeaderboard(leaderboardID:String, timescope:String,
                                               onComplete:Function, onError:Function):void
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
        
        public static function get language():String { return sLanguage; }
        public static function set language(value:String):void { sLanguage = value; }
        
        public static function loadLocalizations(onComplete:Function, onError:Function):void
        {
            // TODO
        }
        
        public static function localize(key:String, deflt:String=null, ...args):String
        {
            return deflt ? deflt : key;
        }
        
        // player management
        
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
        
        // stuff store
        
        // onComplete(resource:Object):void;
        // onError(error:String):void;
        public static function loadSharedData(path:String, 
                                              onComplete:Function, onError:Function):void
        {
        }
        
        // onComplete():void;
        // onError(error:String):void;
        public static function saveSharedData(path:String, object:Object, publicPermissions:String,
                                              onComplete:Function=null, onError:Function=null):void
        {
        }
        
        // onComplete():void
        // onError(error:String):void
        public static function deleteSharedData(path:String, 
                                                onComplete:Function=null, onError:Function=null):void
        {
        }
        
        // onComplete(resource:Object):void;
        // onError(error:String):void;
        public static function loadPlayerData(path:String, 
                                              onComplete:Function, onError:Function):void
        {
        }
        
        // onComplete():void;
        // onError(error:String):void;
        public static function savePlayerData(path:String, object:Object,
                                              onComplete:Function=null, onError:Function=null):void
        {
        }
        
        // onComplete():void
        // onError(error:String):void
        public static function deletePlayerData(path:String, 
                                                onComplete:Function=null, onError:Function=null):void
        {
        }
        
        // properties
        
        public static function get gameID():String { return sGameID; }
        public static function get gameKey():String { return sGameKey; }
        public static function get gameVersion():String { return sGameVersion; }
    }
}