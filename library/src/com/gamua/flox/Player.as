// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.utils.createUID;

    /** An Entity that contains information about a Flox Player. */
    [Type(".player")]
    public class Player extends Entity
    {
        private var mAuthType:String;
        private var mAuthID:String;
        private var mDisplayName:String;
        
        public function Player()
        {
            super.ownerID = this.id;
            
            mAuthType = AuthenticationType.GUEST;
            mAuthID = createUID();
            mDisplayName = "Guest-" + int(Math.random() * 10000);
        }
        
        public function get authType():String { return mAuthType; }
        public function set authType(value:String):void { mAuthType = value; }
        
        public function get authID():String { return mAuthID; }
        public function set authID(value:String):void { mAuthID = value; }
        
        public function get displayName():String { return mDisplayName; }
        public function set displayName(value:String):void { mDisplayName = value; }
    }
}