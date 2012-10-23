package com.gamua.flox
{
    public final class TestHelpers
    {
        public function TestHelpers() { throw new Error("This class cannot be instantiated."); }
        
        public static function initFlox():void
        {
            Flox.initWithBaseURL(Constants.GAME_ID, Constants.GAME_KEY, "1.0",
                                 Constants.BASE_URL);
        }
    }
}