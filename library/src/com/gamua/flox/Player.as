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
        
        public function Player()
        {
            super.ownerID = this.id;
            
            mAuthType = AuthenticationType.GUEST;
            mAuthID = createUID();
        }
        
        /** Log in a new player with the given authentication information. If you pass no
         *  parameters, a new guest will be logged in; the 'Flox.localPlayer' parameter will
         *  immediately reference that player.
         * 
         *  <p>Flox requires that there's always a player logged in. Thus, there is no 'logout'  
         *  method. If you want to remove the reference to the current player, just call  
         *  'login' again (without arguments). The previous player will then be replaced 
         *  by a new guest.</p> 
         *  
         *  @param authType:    The type of authentication you want to use.
         *  @param authID:      The id of the player in its authentication system.
         *  @param authToken:   The token you received from the player's authentication system.  
         *  @param onComplete:  function onComplete(localPlayer:Player):void;
         *  @param onError:     function onError(error:String):void;
         */
        public static function login(
            authType:String="guest", authID:String=null, authToken:String=null,
            onComplete:Function=null, onError:Function=null):void
        {
            Flox.checkInitialized();
            // Flox.clearCache(); TODO: maybe clear cache due to permissions
            
            if (authType == AuthenticationType.GUEST)
            {
                if (authID == null) authID = createUID();
                if (authToken == null) authToken = createUID();

                var player:Player = new Flox.playerClass();
                player.authID = authID;
                player.authType = authType;
                
                Flox.authentication = new Authentication(player.id, authType, authID, authToken);
                Flox.localPlayer = player;
            }
            else
            {
                throw new ArgumentError("Authentication type not supported: " + authType);
            }
        }
        
        /** The current local player. */
        public static function get local():Player
        {
            return Flox.localPlayer;
        }

        public function get authType():String { return mAuthType; }
        public function set authType(value:String):void { mAuthType = value; }
        
        public function get authID():String { return mAuthID; }
        public function set authID(value:String):void { mAuthID = value; }
    }
}