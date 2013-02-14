// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    /** This class stores information about how the current player was authenticated. */
    internal final class Authentication
    {
        private var mPlayerID:String;
        private var mType:String;
        private var mID:String;
        private var mToken:String;
        
        /** Create an Authentication instance with the given parameters. */
        public function Authentication(playerID:String="unknown", 
                                       type:String="guest", id:String=null, token:String=null)
        {
            mPlayerID = playerID;
            mType = type;
            mID = id;
            mToken = token;
        }
        
        /** Creates a duplicate of the authentication object. */
        public function clone():Authentication
        {
            return new Authentication(mPlayerID, mType, mID, mToken);
        }
        
        // properties
        // since this class is saved in a SharedObject, everything has to be R/W!
        
        /** The player ID of the authenticated player. */
        public function get playerId():String { return mPlayerID; }
        public function set playerId(value:String):void { mPlayerID = value; }
        
        /** The authentication type, which is one of the strings defined in the 
         *  'AuthenticationType' class. */
        public function get type():String { return mType; }
        public function set type(value:String):void { mType = value; }
        
        /** The authentication ID, which is the id of the player in the authentication realm
         *  (e.g. a Facebook user ID). */
        public function get id():String { return mID; }
        public function set id(value:String):void { mID = value; }
        
        /** The token that identifies the session within the authentication realm. */
        public function get token():String { return mToken; }
        public function set token(value:String):void { mToken = value; }
    }
}