package com.gamua.flox 
{
    import com.gamua.flox.utils.createURL;

    public class Constants
    {
        [Embed(source="../../../../config/live-server.xml", mimeType="application/octet-stream")]
        private static const server_config:Class;
        private static const ServerConfig:XML = XML(new server_config());
        
        public static const LEADERBOARD_ID:String = "default";
        
        public static function get GAME_ID():String
        {
            return ServerConfig.Game.(@status == "enabled").ID;
        }
        
        public static function get GAME_KEY():String
        {
            return ServerConfig.Game.(@status == "enabled").Key;
        }
        
        public static function get BASE_URL():String
        {
            return ServerConfig.BaseURL;
        }
        
        public static function get ENABLED_HERO_KEY():String
        {
            return ServerConfig.Hero.(@status == "enabled").Key;
        }
        
        public static function get DISABLED_HERO_KEY():String
        {
            return ServerConfig.Hero.(@status == "disabled").Key;
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
            Flox.initWithBaseURL(GAME_ID, GAME_KEY, Flox.VERSION, BASE_URL);
        }
        
        public static function initFloxForGameOverQuota():void
        {
            const gameID:String  = ServerConfig.Game.(@status == "overQuota").ID;
            const gameKey:String = ServerConfig.Game.(@status == "overQuota").Key;
            
            Flox.traceLogs = false;
            Flox.reportAnalytics = false;
            Flox.initWithBaseURL(gameID, gameKey, Flox.VERSION, BASE_URL);
        }
    }
}