// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.utils.HttpMethod;
    import com.gamua.flox.utils.HttpStatus;
    import com.gamua.flox.utils.execute;
    
    import flash.errors.IllegalOperationError;
    import flash.utils.setTimeout;
    
    /** An Entity that contains information about a Flox Player. The class also contains static
     *  methods for Player login and logout. */
    [Type(".player")]
    public class Player extends Entity
    {
        private var mAuthType:String;
        private var mAuthId:String;
        
        /** Don't call this method directly; use the 'Player.login' methods instead. */
        public function Player()
        {
            super.ownerId = this.id;
            super.publicAccess = Access.READ;
            
            mAuthType = null;
            mAuthId   = null;
        }
        
        /** Log in a player with the given authentication information. If you pass no
         *  parameters, a new guest will be logged in; the 'Flox.currentPlayer' parameter will
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
         *  @param onComplete:  function onComplete(currentPlayer:Player):void;
         *  @param onError:     function onError(error:String, httpStatus:int):void;
         */
        public static function login(
            authType:String="guest", authId:String=null, authToken:String=null,
            onComplete:Function=null, onError:Function=null):void
        {
            Flox.checkInitialized();
            
            if (authId    == null) authId    = "";
            if (authToken == null) authToken = "";
            
            if (authType == AuthenticationType.GUEST)
            {
                var player:Player = new Flox.playerClass();
                player.authId = authId;
                player.authType = authType;
                
                onAuthenticated(player);
            }
            else
            {
                var authData:Object = { authType: authType, authId: authId, authToken: authToken };
                
                if (current.authType == AuthenticationType.GUEST) 
                    authData.id = current.id; 
                
                Flox.service.request(HttpMethod.POST, "authenticate", authData, 
                                     onRequestComplete, onError);
            }
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                var id:String = body.id;
                var type:String = getType(Flox.playerClass);
                var eTag:String = body.eTag;
                var player:Player = Entity.fromObject(type, id, body.entity) as Player;
                onAuthenticated(player);
            }
            
            function onAuthenticated(player:Player):void
            {
                Flox.clearCache();
                Flox.authentication = new Authentication(player.id, authType, authId, authToken);
                Flox.currentPlayer = player;
                execute(onComplete, player);
            }
        }
        
        /** Logs the current player out and immediately creates a new guest player.
         *  (In Flox, 'Player.current' will always return a player object.) */
        public static function logout():void
        {
            // we always need an active player! The login method, called without arguments,
            // will create a new one for us.
            
            login();
        }
        
        /** Log in a player with his email address. 
         *  
         *  <ul><li>If this is the first time this email address is used, the current guest player 
         *  will be converted into a player with auth-type "EMAIL".</li>
         *  <li>When the player tries to log in with the same address on another device,
         *  he will get an e-mail with a confirmation link, and the login will fail until the
         *  player clicks on that link.</li></ul>
         * 
         *  <p>In case of an error, the HTTP status tells you if a confirmation mail was sent:
         *  "HttpStatus.FORBIDDEN" means that the mail was sent; "HttpStatus.TOO_MANY_REQUESTS"
         *  means that a mail has already been sent within the last 15 minutes.</p>
         *  
         *  @param email:      The e-mail address of the player trying to log in.  
         *  @param onComplete: function onComplete(currentPlayer:Player):void;
         *  @param onError:    function onError(error:String, httpStatus:int, confirmationMailSent:Boolean):void;*/ 
        public static function loginWithEmail(email:String, 
                                              onComplete:Function, onError:Function):void
        {
            login(AuthenticationType.EMAIL, email, Flox.installationID, onComplete, onLoginError);
            
            function onLoginError(error:String, httpStatus:int):void
            {
                execute(onError, error, httpStatus, httpStatus == HttpStatus.FORBIDDEN);
            }
        }
        
        /** Log in a player with just a single 'key' string. The typical use-case of this
         *  authentication is to combine Flox with other APIs that have their own user database 
         *  (e.g. Mochi, Kongregate, GameCenter, etc). */
        public static function loginWithKey(key:String, onComplete:Function, onError:Function):void
        {
            login(AuthenticationType.KEY, key, null, onComplete, onError); 
        }
        
        /** The current local player. */
        public static function get current():Player
        {
            return Flox.currentPlayer;
        }

        /** The type of authentication the player used to log in. */
        public function get authType():String { return mAuthType; }
        public function set authType(value:String):void
        {
            if (mAuthType != null && mAuthType != value)
                throw new IllegalOperationError("Cannot change the authentication type of a Player entity.");
            else
                mAuthType = value; 
        }
        
        /** The main identifier of the player's authentication system. */
        public function get authId():String { return mAuthId; }
        public function set authId(value:String):void 
        { 
            if (mAuthId != null && mAuthId != value)
                throw new IllegalOperationError("Cannot change the authentication ID of a Player entity.");
            else
                mAuthId = value; 
        }
        
        /** @private */
        public override function refresh(onComplete:Function, onError:Function):void
        {
            // a guest is not necessarily stored on the server; and even if it is, only the
            // current installation can access it. Thus, it will always be in the correct state.
            
            if (mAuthType == AuthenticationType.GUEST)
                setTimeout(execute, 1, onComplete, this, true);
            else
                super.refresh(onComplete, onError);
        }
        
        /** @private */
        public override function set publicAccess(value:String):void
        {
            if (value != Access.READ)
                throw new IllegalOperationError("Cannot change access rights of a Player entity.");
            else
                super.publicAccess = value;
        }
    }
}