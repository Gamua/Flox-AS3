package tests
{
    import com.gamua.flox.utils.createURL;

    public class Constants
    {
        public static const PRODUCTION_SERVER:Boolean = true;
        
        public static function get GAME_ID():String
        {
            return PRODUCTION_SERVER ? "unit-test-app" : "unit-test-app";
        }
        
        public static function get GAME_KEY():String
        {
            return PRODUCTION_SERVER ? "7e143737-6af5-4c66-a261-ea0e0fe7e047" :
                                       "12c866d1-761d-482f-9d9a-1d817c2a292c";
        }
        
        public static function get LEADERBOARD_ID():String
        {
            return PRODUCTION_SERVER ? "default" : "default";
        }
        
        public static function get BASE_URL():String
        {
            return PRODUCTION_SERVER ? "http://www.flox.cc/api" :
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
    }
}