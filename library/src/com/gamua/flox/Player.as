package com.gamua.flox
{
    import com.gamua.flox.utils.createUID;

    public class Player
    {
        private var mID:String;
        private var mName:String;
        private var mCountry:String;
        
        public function Player(id:String=null, name:String=null, country:String="us") 
        {
            mID = id ? id : createUID();
            mName = name ? name : "Player";
            mCountry = country;
        }
        
        public function get id():String { return mID; }
        public function set id(value:String):void { mID = value; }
        
        public function get name():String { return mName; }
        public function set name(value:String):void { mName = value; }
        
        public function get country():String { return mCountry; }
        public function set country(value:String):void { mCountry = value; }
    }
}