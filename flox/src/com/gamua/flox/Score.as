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
        private var mPlayerId:String;
        private var mPlayerName:String;
        private var mValue:int;
        private var mDate:Date;
        private var mCountry:String;
        
        /** Create a new score instance with the given values. */
        public function Score(playerId:String=null, playerName:String=null,
                              value:int=0, date:Date=null, country:String=null)
        {
            mPlayerId = playerId ? playerId : "unknown";
            mPlayerName = playerName ? playerName : "unknown";
            mCountry = country ? country : "us";
            mValue = value;
            mDate = date ? date : new Date();
        }
        
        /** The ID of the player who posted the score. Note that this could be a guest player
         *  unknown to the server. */
        public function get playerId():String { return mPlayerId; }
        public function set playerId(value:String):void { mPlayerId = value; }

        /** The name of the player who posted the score. */
        public function get playerName():String { return mPlayerName; }
        public function set playerName(value:String):void { mPlayerName = value; }

        /** The actual value/score. */
        public function get value():int { return mValue; }
        public function set value(value:int):void { mValue = value; }
        
        /** The date at which the score was posted. */
        public function get date():Date { return mDate; }
        public function set date(value:Date):void { mDate = value; }
        
        /** The country from which the score originated, in a two-letter country code. */
        public function get country():String { return mCountry; }
        public function set country(value:String):void { mCountry = value; }

        /** Returns a description of the score. */
        public function toString():String
        {
            return formatString('[Score playerName="{0}" value="{1}" country="{2}" date="{3}"]',
                mPlayerName, mValue, mCountry, DateUtil.toString(mDate));
        }
    }
}