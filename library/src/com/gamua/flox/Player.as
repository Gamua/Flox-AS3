package com.gamua.flox
{
    import com.gamua.flox.utils.createUID;

    public class Player extends Entity
    {
        public static const TYPE:String = ".player";
        
        private var mAuthType:String;
        private var mAuthID:String;
        private var mDisplayName:String;
        
        public function Player(id:String=null) 
        {
            super(TYPE, id);
            super.ownerID = this.id;
            
            mAuthType = AuthenticationType.GUEST;
            mAuthID = createUID();
            mDisplayName = "Guest-" + int(Math.random() * 10000);
        }
        
        public static function load(id:String, onComplete:Function, onError:Function):void
        {
            Entity.load(TYPE, id, onComplete, onError);
        }
        
        public function get authType():String { return mAuthType; }
        public function set authType(value:String):void { mAuthType = value; }
        
        public function get authID():String { return mAuthID; }
        public function set authID(value:String):void { mAuthID = value; }
        
        public function get displayName():String { return mDisplayName; }
        public function set displayName(value:String):void { mDisplayName = value; }
    }
}