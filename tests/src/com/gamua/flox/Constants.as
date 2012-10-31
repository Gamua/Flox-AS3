package com.gamua.flox 
{
    import com.gamua.flox.utils.createURL;

    public class Constants
    {
        public static const PRODUCTION_SERVER:Boolean = true;
        
        public static const GAME_ID:String = "gamua-unit-tests";
        public static const LEADERBOARD_ID:String = "default";
        
        
        public static function get GAME_KEY():String
        {
            return PRODUCTION_SERVER ? "150a1bb6-b33d-4eb3-8848-23051f200359" :
                                       "0d53277c-39ba-4519-8920-07a1a5af9581";
        }
        
        public static function get BASE_URL():String
        {
            return PRODUCTION_SERVER ? "https://www.flox.cc/api" :
                                       "http://192.168.11.132:8000/api";
        }
        
        public static function createGameUrl(...args):String
        {
            return createURL("games", GAME_ID, createURL(args)); 
        }
        
        public static function createLeaderboardUrl(...args):String
        {
            return createURL("games", GAME_ID, "leaderboards", LEADERBOARD_ID, createURL(args));
        }
        
        public static function initFlox(reportAnalytics:Boolean=false):void
        {
            Flox.traceLogs = false;
            Flox.reportAnalytics = reportAnalytics;
            Flox.initWithBaseURL(GAME_ID, GAME_KEY, "1.0", BASE_URL);
        }
    }
}