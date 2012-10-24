package com.gamua.flox
{
    /** A utility class providing string constants for leaderboard time ranges. */
    public class TimeScope
    {
        public function TimeScope() { throw new Error("This class cannot be instantiated."); }
        
        public static const TODAY:String     = "today";
        public static const THIS_WEEK:String = "thisWeek";
        public static const ALL_TIME:String  = "allTime";
    }
}