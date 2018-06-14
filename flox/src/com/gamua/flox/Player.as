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
    
    /** An Entity that contains information about a Flox Player. The class also contains static
     *  methods for Player login and logout. 
     *
     *  <p>Do not create player instances yourself; instead, always use the player objects returned
     *  by 'Player.current'. A guest player is created automatically for you on first start
     *  (as a guest player).</p>
     *
     *  <p>The current player is automatically persisted, i.e. when you close and restart your game,
     *  the same player will be logged in automatically.</p>
     *
     *  <p>In many games, you'll want to use a custom player subclass, so that you can add custom
     *  properties. To do that, register your player class before starting Flox.</p>
     *  <pre>
     *  Flox.playerClass = CustomPlayer;</pre>
     *
     *  <p>When you've done that, you can get your player anytime with this code:</p>
     *  <pre>
     *  var player:CustomPlayer = Player.current as CustomPlayer;</pre>
     */
    [Type(".player")]
    public class Player extends Entity
    {
        private var mAuthType:String;
        
        /** Don't call this method directly; use the 'Player.login' methods instead. */
        public function Player()
        {
            super.ownerId = this.id;
            super.publicAccess = Access.READ;
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
         *  @param authType     The type of authentication you want to use.
         *  @param authId       The id of the player in its authentication system.
         *  @param authToken    The token you received from the player's authentication system.
         *  @param onComplete   function onComplete(currentPlayer:Player):void;
         *  @param onError      function onError(error:String, httpStatus:int):void;
         */
        public static function login(
            authType:String="guest", authId:String=null, authToken:String=null,
            onComplete:Function=null, onError:Function=null):void
        {
            var authData:Object = { authType: authType, authId: authId, authToken: authToken };
            loginWithAuthData(authData, onComplete, onError);
        }

        private static function loginWithAuthData(authData:Object, onComplete:Function=null,
                                                  onError:Function=null):void
        {
            Flox.checkInitialized();
            var previousAuthentication:Authentication = Flox.authentication;
            
            if (authData.authType == AuthenticationType.GUEST)
            {
                var player:Player = new Flox.playerClass();
                player.authType = AuthenticationType.GUEST;
                
                onAuthenticated(player);
            }
            else
            {
                if (current.authType == AuthenticationType.GUEST) 
                    authData.id = current.id; 
                
                Flox.service.request(HttpMethod.POST, "authenticate", authData, 
                    onRequestComplete, onRequestError);

                Flox.authentication = null; // prevent any new requests while login is in process!
            }

            function onRequestComplete(body:Object, httpStatus:int):void
            {
                // authToken may be overridden (e.g. so that password is not stored locally)
                if (body.authToken) authData.authToken = body.authToken;

                var id:String = body.id;
                var type:String = getType(Flox.playerClass);
                var player:Player = Entity.fromObject(type, id, body.entity) as Player;
                onAuthenticated(player);
            }

            function onRequestError(error:String, httpStatus:int):void
            {
                Flox.authentication = previousAuthentication;
                execute(onError, error, httpStatus);
            }

            function onAuthenticated(player:Player):void
            {
                Flox.clearCache();
                Flox.currentPlayer = player;
                Flox.authentication = new Authentication(player.id,
                    authData.authType, authData.authId, authData.authToken);

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
        
        /** Log in a player with just a single 'key' string. The typical use-case of this
         *  authentication is to combine Flox with other APIs that have their own user database
         *  (e.g. Mochi, Kongregate, GameCenter, etc). */
        public static function loginWithKey(key:String, onComplete:Function, onError:Function):void
        {
            login(AuthenticationType.KEY, key, null, onComplete, onError);
        }

        /** Log in a player with his e-mail address.
         *  
         *  <ul><li>If this is the first time this e-mail address is used, the current guest player
         *  will be converted into a player with auth-type "EMAIL".</li>
         *  <li>When the player tries to log in with the same address on another device,
         *  he will get an e-mail with a confirmation link, and the login will fail until the
         *  player clicks on that link.</li></ul>
         * 
         *  <p>In case of an error, the HTTP status tells you if a confirmation mail was sent:
         *  "HttpStatus.FORBIDDEN" means that the mail was sent; "HttpStatus.TOO_MANY_REQUESTS"
         *  means that a mail has already been sent within the last 15 minutes.</p>
         *  
         *  @param email       The e-mail address of the player trying to log in.
         *  @param onComplete  function onComplete(currentPlayer:Player):void;
         *  @param onError     function onError(error:String, httpStatus:int, confirmationMailSent:Boolean):void;*/
        public static function loginWithEmail(email:String, 
                                              onComplete:Function, onError:Function):void
        {
            login(AuthenticationType.EMAIL, email, Flox.installationID, onComplete, onLoginError);
            
            function onLoginError(error:String, httpStatus:int):void
            {
                execute(onError, error, httpStatus, httpStatus == HttpStatus.FORBIDDEN);
            }
        }
        
        /** Log in a player with his e-mail address and a password.
         *
         *  <p>Depending on the 'loginOnly' parameter, this method can also be used to sign up
         *  a previously unknown player. Once an e-mail address is confirmed, a login will only
         *  work with the correct password.</p>
         *
         *  <ul>
         *  <li>If the e-mail + password combination is correct, the player will be logged in —
         *      regardless of the 'loginOnly' setting.</li>
         *  <li>If 'loginOnly = true' and the mail address is unknown or the password is wrong,
         *      the method will yield an error with HttpStatus.FORBIDDEN.</li>
         *  <li>If 'loginOnly = false' and the mail address is used for the first time, the player
         *      receives a confirmation mail and the method yields an error with
         *      HttpStatus.UNAUTHORIZED.</li>
         *  <li>If 'loginOnly = false' and the mail address was not yet confirmed, or if the
         *      mail address was already registered with a different password, the method will
         *      yield an error with HttpStatus.FORBIDDEN.</li>
         *  </ul>
         *
         *  <p>If the player forgets the password, you can let him acquire a new one with the
         *  'resetEmailPassword' method.</p>
         *
         *  @param email       The e-mail address of the player trying to log in or sign up.
         *  @param password    The password of the player trying to log in or sign up.
         *  @param loginOnly   If true, the email/password combination must already exist.
         *                     If false, an e-mail address that was used for the first time will
         *                     trigger a confirmation e-mail.
         *  @param onComplete  function onComplete(currentPlayer:Player):void;
         *  @param onError     function onError(error:String, httpStatus:int, confirmationMailSent:Boolean):void;
         */
        public static function loginWithEmailAndPassword(
            email:String, password:String, loginOnly:Boolean,
            onComplete:Function, onError:Function):void
        {
            var authData:Object =
            {
                authType:  AuthenticationType.EMAIL_AND_PASSWORD,
                authId:    email,
                authToken: password,
                loginOnly: loginOnly
            };

            loginWithAuthData(authData, onComplete, onLoginError);

            function onLoginError(error:String, httpStatus:int):void
            {
                execute(onError, error, httpStatus, httpStatus == HttpStatus.UNAUTHORIZED);
            }
        }

        /** Causes the server to send a password-reset e-mail to the player's e-mail address. If
         *  that address is unknown to the server, it will yield an error with HttpStatus.NOT_FOUND.
         *
         *  @param onComplete  function onComplete():void;
         *  @param onError     function onError(error:String, httpStatus:int):void;
         */
        public static function resetEmailPassword(email:String, onComplete:Function,
                                                  onError:Function):void
        {
            Flox.service.request(HttpMethod.POST, "resetPassword", { email: email },
                                 onComplete, onError);
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