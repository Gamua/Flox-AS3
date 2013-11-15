// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    /** A utility class providing string constants for leaderboard time ranges. */
    public class TimeScope
    {
        /** @private */
        public function TimeScope() { throw new Error("This class cannot be instantiated."); }
        
        /** All scores of this day. */
        public static const TODAY:String     = "today";
        
        /** All scores of the current week. */
        public static const THIS_WEEK:String = "thisWeek";
        
        /** The scores of all time. */
        public static const ALL_TIME:String  = "allTime";
    }
}