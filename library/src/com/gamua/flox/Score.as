// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.formatString;

    /** Provides information about the value and origin of one posted score entry. */
    public class Score
    {
        private var mValue:int;
        private var mPlayerName:String;
        private var mDate:Date;
        private var mCountry:String;
        
        /** Create a new score instance with the given values. */
        public function Score(playerName:String, country:String, value:int, date:Date)
        {
            mPlayerName = playerName;
            mCountry = country;
            mValue = value;
            mDate = new Date(date.time);
        }
        
        /** The actual value/score. */
        public function get value():int { return mValue; }
        
        /** The name of the player who posted the score. */
        public function get playerName():String { return mPlayerName; }
        
        /** The date at which the score was posted. */
        public function get date():Date { return mDate; }
        
        /** The country from which the score originated, in a two-letter country code. */
        public function get country():String { return mCountry; }
        
        /** Returns a description of the score. */
        public function toString():String
        {
            return formatString('[Score playerName="{0}" value="{1}" country="{2}" date="{3}"]',
                mPlayerName, mValue, mCountry, DateUtil.toString(mDate));
        }
    }
}