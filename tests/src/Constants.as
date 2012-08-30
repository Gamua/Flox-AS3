package 
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
            return PRODUCTION_SERVER ? "fefe241a-b7d0-4baf-b708-e2946fd99188" :
                                       "92258dbd-8178-4b48-bbe9-bbaf0ea65e17";
        }
        
        public static function get LEADERBOARD_ID():String
        {
            return PRODUCTION_SERVER ? "default" : "default";
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
    }
}