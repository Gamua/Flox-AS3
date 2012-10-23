package com.gamua.flox
{
    internal final class Authentication
    {
        private var mPlayerID:String;
        private var mType:String;
        private var mID:String;
        private var mToken:String;
        
        public function Authentication(playerID:String="unknown", 
                                       type:String="guest", id:String=null, token:String=null)
        {
            mPlayerID = playerID;
            mType = type;
            mID = id;
            mToken = token;
        }
        
        // properties
        // since this class is saved in a SharedObject, everything has to be R/W!
        
        public function get playerID():String { return mPlayerID; }
        public function set playerID(value:String):void { mPlayerID = value; }
        
        public function get type():String { return mType; }
        public function set type(value:String):void { mType = value; }
        
        public function get id():String { return mID; }
        public function set id(value:String):void { mID = value; }
        
        public function get token():String { return mToken; }
        public function set token(value:String):void { mToken = value; }
    }
}