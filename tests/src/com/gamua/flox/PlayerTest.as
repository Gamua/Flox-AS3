package com.gamua.flox
{
    import com.gamua.flox.utils.CustomEntity;
    import com.gamua.flox.utils.HttpStatus;
    import com.gamua.flox.utils.createUID;
    import com.gamua.flox.utils.downloadTextResource;
    import com.gamua.flox.utils.setTimeout;
    
    import starling.unit.UnitTest;
    
    public class PlayerTest extends UnitTest
    {
        public override function setUp():void
        {
            Flox.playerClass = CustomPlayer;
            Constants.initFlox();
            Player.logout();
        }
        
        public override function tearDown():void
        {
            Flox.shutdown();
        }
        
        public function testCustomPlayer():void
        {
            var player:CustomPlayer = new CustomPlayer("Baggins");
            assertEqual(player.type, ".player");
        }
        
        public function testChangeInhibitedPlayerProperties():void
        {
            var player:CustomPlayer = Player.current as CustomPlayer;
            
            try
            {
                player.authType = AuthenticationType.KEY;
                fail("Changing auth key did not fail");
            }
            catch (e:Error) {}
            
            try
            {
                player.publicAccess = Access.NONE;
                fail("Changing public access rights did not fail");
            }
            catch (e:Error) {}
        }
        
        public function testPlayerClassMustExtendPlayer():void
        {
            var failed:Boolean = false;
            Flox.shutdown();
            
            try
            {
                Flox.playerClass = Entity;
                fail("Could assign non-Player class to Flox.playerClass");
            }
            catch (e:Error) {}
        }

        public function testGuestLogin():void
        {
            var defaultGuest:Player = Player.current;
            assertNotNull(defaultGuest);
            assertNotNull(defaultGuest.id);
            assertEqual(".player", defaultGuest.type);
            assertEqual(AuthenticationType.GUEST, defaultGuest.authType);
            
            Player.login();
            var newGuest:Player = Player.current;
            assert(defaultGuest != newGuest);
            assert(defaultGuest.id != newGuest.id);
        }
        
        public function testLoginCustomPlayer():void
        {
            var player:CustomPlayer = Player.current as CustomPlayer;
            var playerID:String = player.id;
            var lastName:String = "Baggins";
            player.lastName = lastName;
            
            assertNotNull(player);
            
            Flox.shutdown();
            
            Constants.initFlox();
            assertEqual(playerID, Player.current.id);
            assertEqual(lastName, (Player.current as CustomPlayer).lastName);
        }
        
        public function testLoginWithKey(onComplete:Function):void
        {
            var guest:CustomPlayer = Player.current as CustomPlayer;
            var key:String = "SECRET#" + createUID();
            var guestID:String = guest.id;
            
            Player.loginWithKey(key, onLoginComplete, onError);
            
            function onLoginComplete(player:Player):void
            {
                assertEqual(player.id, guestID);
                assertEqual(Player.current.id, guestID);
                assertEqual(AuthenticationType.KEY, player.authType);
                
                Player.logout();
                
                assert(Player.current.id != guestID);
                
                Player.loginWithKey(key, onSecondLoginComplete, onError);
            }
            
            function onSecondLoginComplete(player:Player):void
            {
                assertEqual(player.id, guestID);
                assertEqual(Player.current.id, guestID);
                onComplete();
            }
            
            function onError(error:String, httpStatus:int):void
            {
                fail("login with key did not work. Error: " + error);
                onComplete();
            }
        }
        
        public function testLoginWithKeyAndSavePlayer(onComplete:Function):void
        {
            var name:String = "Picard"
            var guest:CustomPlayer = Player.current as CustomPlayer;
            var key:String = "SECRET#" + createUID();
            var guestID:String = guest.id;
            
            Player.loginWithKey(key, onLoginComplete, onLoginError);
            
            function onLoginComplete(player:CustomPlayer):void
            {
                player.lastName = name;
                player.save(onSaveComplete, onSaveError);
            }
            
            function onLoginError(error:String, httpStatus:int):void
            {
                fail("login with key did not work. Error: " + error);
                onComplete();
            }
            
            function onSaveComplete(player:CustomPlayer):void
            {
                assertEqual(name, player.lastName, "name not saved");
                assertEqual(player.id, guestID);
                onComplete();
            }
            
            function onSaveError(error:String):void
            {
                fail("Error on save: " + error);
                onComplete();
            }
        }
        
        public function testLoginWithEmail(onComplete:Function):void
        {
            var oldPlayerID:String = Player.current.id;
            Player.logout();
            
            var guestID:String = Player.current.id;
            assert(oldPlayerID != guestID);

            var email:String = createUID().toLowerCase() + "@incognitek.com";
            Player.loginWithEmail(email, onLogin1Complete, onLogin1Error);
            
            function onLogin1Complete(player:Player):void
            {
                // first login should work right away.
                assertEqual(player.id, guestID); // guest has been upgraded
                assertEqual(Player.current.id, player.id);
                assertEqual(AuthenticationType.EMAIL, player.authType);
                
                // changing the player here caused a problem on the server-side once, 
                // so we do that here.
                (player as CustomPlayer).lastName = "changed";
                player.saveQueued();
                
                // now log out and retry on a different device
                Flox.resetInstallationID();
                Player.logout();
                Player.loginWithEmail(email, onLogin2Complete, onLogin2Error);
            }
            
            function onLogin1Error(error:String, httpStatus:int, confirmationMailSent:Boolean):void
            {
                fail("first login produced error: " + error);
                onComplete();
            }
            
            function onLogin2Complete(player:Player):void
            {
                fail("login attempt on different device should have failed, but succeeded");
                onComplete();
            }
            
            function onLogin2Error(error:String, httpStatus:int, confirmationMailSent:Boolean):void
            {
                if (confirmationMailSent)
                {
                    assertEqual(HttpStatus.FORBIDDEN, httpStatus, "wrong http status on re-login");
                    
                    // now try the login again BEFORE activating the mail
                    Player.loginWithEmail(email, onPrematureLoginComplete, onPrematureLoginError);
                }
                else
                {
                    fail("login via e-mail procedure did not work. Error: " + error);
                    onComplete();
                }
            }
            
            function onPrematureLoginComplete(player:Player):void
            {
                fail("login attempt before clicking activation link should have failed, but succeeded");
                onComplete();
            }
            
            function onPrematureLoginError(error:String, httpStatus:int, mailSent:Boolean):void
            {
                assertEqual(HttpStatus.TOO_MANY_REQUESTS, httpStatus);
                assertFalse(mailSent);
                
                // now activate player
                activatePlayerThroughEmail(email, onPlayerActivated, onMailError);
            }
            
            function onPlayerActivated():void
            {
                // authentication url visited! Now we can log in.
                Player.loginWithEmail(email, onFinalLoginComplete, onFinalLoginError);
            }
            
            function onMailError(error:String, httpStatus:int):void
            {
                fail("Could not access mail server: " + error);
                onComplete();
            }
            
            function onFinalLoginComplete(player:Player):void
            {
                assertEqual(guestID, player.id);
                onComplete();
            }
            
            function onFinalLoginError(error:String):void
            {
                fail("Login after mail activation did not work!");
                onComplete();
            }
        }
        
        private function fetchEmail(email:String, onComplete:Function, onError:Function):void
        {
            // We use Gamua's own mail server to get those activation mails.
            
            var numTries:int = 10;
            var delay:int = 1000;
            var emailUser:String = email.split("@").shift();
            var mailDumpUrl:String = "http://www.incognitek.com/maildump/" + emailUser + ".txt";
            
            setTimeout(downloadTextResource, delay, mailDumpUrl, onDownloadComplete, onDownloadError);
            
            function onDownloadComplete(rawContents:String):void
            {
                onComplete(rawContents.replace(/=[\r\n]+/g, "").replace(/=3D/g, "="));
            }
            
            function onDownloadError(error:String, httpStatus:int):void
            {
                if (numTries-- > 0)
                {
                    trace("  mail not yet arrived, trying again ...");
                    setTimeout(downloadTextResource, delay, mailDumpUrl, 
                               onDownloadComplete, onDownloadError);
                }
                else
                {
                    onError("Error fetching mail", httpStatus);
                }
            }
        }
        
        private function activatePlayerThroughEmail(email:String, 
                                                    onComplete:Function, onError:Function):void
        {
            fetchEmail(email, onDownloadComplete, onError);
            
            function onDownloadComplete(contents:String):void
            {
                // find link to flox email, visit it.
                var matches:Array = contents.match(
                    '<a href="(https?://(?:www.)?flox.*/games/.+?/players/.+?/authorize.+?)"');
                if (matches && matches.length == 2)
                    downloadTextResource(matches[1], onAuthorizeComplete, onError);
                else
                    onError("Could not find Flox link in mail");
            }
            
            function onAuthorizeComplete(htmlContents:String):void
            {
                onComplete();
            }
        }
        
        private function fetchNewEmailPassword(email:String, onComplete:Function, onError:Function):void
        {
            // if the mail has not arrived in time, we'll still find the confirmation mail instead
            // of the one to reset the password. So we have to retry several times.
            
            var numTries:int = 10;
            fetchEmail(email, onDownloadComplete, onError);
            
            function onDownloadComplete(contents:String):void
            {
                // find link to flox email, visit it and fetch new password.
                var matches:Array = contents.match(
                    '<a href="(https?://(?:www.)?flox.*/games/.+?/players/.+?/resetPassword.+?)"');
                if (matches && matches.length == 2)
                    downloadTextResource(matches[1], onNewPasswordDownloadComplete, onError);
                else
                {
                    if (numTries-- > 0)
                        fetchEmail(email, onDownloadComplete, onError);
                    else
                        onError("Could not find Flox link in mail");
                }
            }
            
            function onNewPasswordDownloadComplete(rawContents:String):void
            {
                var matches:Array = rawContents.match(/\<h1\>([a-zA-Z0-9]{6,})\<\/h1\>/);
                if (matches && matches.length == 2)
                    onComplete(matches[1]);
                else
                    onError("Could not find password in web page");
            }
        }
        
        public function testCannotUseSameKeyTwice(onComplete:Function):void
        {
            var key:String = createUID();
            Player.loginWithKey(key, onLoginComplete, onLoginError);
            
            function onLoginComplete(player:CustomPlayer):void
            {
                // by changing the ID and saving the player, we'd (in theory) create a new
                // player object on the server that has the same key. That must not be allowed.
                
                player.id = createUID();
                player.save(onSaveComplete, onSaveError);
            }
            
            function onLoginError(error:String):void
            {
                fail("key login failed");
                onComplete();
            }
            
            function onSaveComplete():void
            {
                fail("server did not prohibit using the same auth ID twice");
                onComplete();
            }
            
            function onSaveError(error:String):void
            {
                // that's fine, it's supposed to fail.
                onComplete();
            }
        }
        
        public function testMakeRequestWhileLoggingIn(onComplete:Function):void
        {
            Flox.clearQueue();
            Player.loginWithKey(createUID(), onLoginComplete, onLoginError);
            
            var completeCount:int = 0;
            var entity:Entity = new CustomEntity();
            entity.save(onSaveComplete, onSaveError);
            
            // this should also happen with "saveQueued", but that can't be tested right now. :|
            
            function onSaveComplete():void
            {
                fail("Could save entity while logging in");
                requestComplete();
            }
            
            function onSaveError(error:String, httpStatus:int):void
            {
                assertEqual(HttpStatus.FORBIDDEN, httpStatus, "wrong http status");
                requestComplete();
            }
            
            function onLoginComplete():void
            {
                requestComplete();
            }
            
            function onLoginError(error:String):void
            {
                fail("Could not make key login");
                requestComplete();
            }
            
            function requestComplete():void
            {
                if (++completeCount == 2)
                    onComplete();
            }
        }
        
        public function testSavePlayerWithAuthId(onComplete:Function):void
        {
            Flox.shutdown();
            Flox.playerClass = CustomPlayerWithAuthId;
            Constants.initFlox();
            
            var guest:CustomPlayerWithAuthId = Player.current as CustomPlayerWithAuthId;
            guest.authId = "not allowed";
            guest.save(onSaveComplete, onSaveError);
            
            function onSaveComplete():void
            {
                fail("could save player with 'authId' property");
                onComplete();
            }
            
            function onSaveError(error:String):void
            {
                // that's supposed to happen.
                onComplete();
            }
        }
        
        public function testLoginWithEmailAndPassword(onComplete:Function):void
        {
            var guestID:String = Player.current.id;
            var email:String = createUID().toLowerCase() + "@incognitek.com";
            var password:String = createUID();
            
            // first, try to login only — should fail.
            
            Player.loginWithEmailAndPassword(email, password, true, onLoginOnlyComplete,
                onLoginOnlyError);
            
            function onLoginOnlyComplete():void
            {
                fail("could login player that was used the first time");
                onComplete();
            }
            
            function onLoginOnlyError(error:String, httpStatus:int):void
            {
                assertEqual(HttpStatus.FORBIDDEN, httpStatus, "wrong http status: " + httpStatus);
                
                // now sign up the user
                
                Player.loginWithEmailAndPassword(email, password, false, onSignUpComplete,
                    onSignUpError);
            }
            
            function onSignUpComplete(signedUpPlayer:CustomPlayer):void
            {
                fail("Sign up worked, but should have sent confirmation mail instead");
                onComplete();
            }
            
            function onSignUpError(error:String, httpStatus:int):void
            {
                assertEqual(HttpStatus.UNAUTHORIZED, httpStatus, "wrong http status: " + httpStatus);
                
                // confirmation mail was sent. We must not be able to login yet, so let's try that.
                
                Player.logout();
                Player.loginWithEmailAndPassword(email, password, true, 
                    onLoginBeforeConfirmationComplete, onLoginBeforeConfirmationError);
            }
            
            function onLoginBeforeConfirmationComplete():void
            {
                fail("Could login before clicking on confirmation link");
                onComplete();
            }
            
            function onLoginBeforeConfirmationError(error:String, httpStatus:int):void
            {
                assertEqual(HttpStatus.FORBIDDEN, httpStatus, "wrong http status: " + httpStatus);
                
                // now click that damned link, alright.
                activatePlayerThroughEmail(email, onConfirmationComplete, onConfirmationError);
            }
            
            function onConfirmationComplete():void
            {
                Player.loginWithEmailAndPassword(email, password, true, 
                    onLoginComplete, onLoginError);
            }
            
            function onConfirmationError(error:String):void
            {
                fail("Could not activate email/password player via mail: " + error);
                onComplete();
            }
            
            function onLoginComplete(signedUpPlayer:CustomPlayer):void
            {
                assertEqual(signedUpPlayer.id, guestID, "sign up did not yield correct player");
                assertEqual(signedUpPlayer.authType, AuthenticationType.EMAIL_AND_PASSWORD,
                    "wrong auth type");
                
                // now try the wrong password
                Player.logout();
                Player.loginWithEmailAndPassword(email, "incorrect-password", true, 
                    onWrongPasswordComplete, onWrongPasswordError);
            }
            
            function onLoginError(error:String, httpStatus:int):void
            {
                fail("Could not log in email/password user — " + error);
                onComplete();
            }
            
            function onWrongPasswordComplete(signedUpPlayer:CustomPlayer):void
            {
                fail("user could login with incorrect password!");
                onComplete();
            }
            
            function onWrongPasswordError(error:String, httpStatus:int):void
            {
                assertEqual(HttpStatus.FORBIDDEN, httpStatus, "wrong http status: " + httpStatus);
                onComplete();
            }
        }
        
        public function testResetEmailPassword(onComplete:Function):void
        {
            var guestID:String = Player.current.id;
            var email:String = createUID().toLowerCase() + "@incognitek.com";
            var password:String = createUID();
            
            // first, we register the new user.
            
            Player.loginWithEmailAndPassword(email, password, false, onRegisterComplete,
                onRegisterError);
            
            function onRegisterComplete():void
            {
                fail("could register new player without confirmation mail");
                onComplete();
            }
            
            function onRegisterError(error:String, httpStatus:int):void
            {
                activatePlayerThroughEmail(email, onConfirmationComplete, onConfirmationError);
            }
            
            function onConfirmationComplete():void
            {
                Player.resetEmailPassword(email, onResetComplete, onResetError);
            }
            
            function onResetComplete():void
            {
                fetchNewEmailPassword(email, onFetchPasswordComplete, onFetchPasswordError);
            }
            
            function onResetError(error:String, httpStatus:int):void
            {
                fail("Could not reset email password: " + error);
                onComplete();
            }
            
            function onConfirmationError(error:String):void
            {
                fail("Could not activate email/password player via mail: " + error);
                onComplete();
            }
                
            function onFetchPasswordComplete(newPassword:String):void
            {
                // now login with new password
                Player.logout()
                Player.loginWithEmailAndPassword(email, newPassword, true, onLoginComplete,
                    onLoginError);
            }
            
            function onFetchPasswordError(error:String):void
            {
                fail("Could not reset password: " + error);
                onComplete();
            }
            
            function onLoginComplete(player:CustomPlayer):void
            {
                assertEqual(player.id, guestID, "login did not yield correct player");
                assertEqual(player.authType, AuthenticationType.EMAIL_AND_PASSWORD, 
                    "wrong auth type");
                
                onComplete();
            }
            
            function onLoginError(error:String, httpStatus:int):void
            {
                fail("Could not login player: " + error);
                onComplete();
            }
        }
        
        public function testLoginWithEmailAndPasswordThenSave(onComplete:Function):void
        {
            var guestID:String = Player.current.id;
            var email:String = createUID().toLowerCase() + "@incognitek.com";
            var password:String = createUID();
            
            Player.loginWithEmailAndPassword(email, password, false, onSignUpComplete,
                onSignUpError);
            
            function onSignUpComplete():void
            {
                fail("Sign up worked, but should have sent confirmation mail instead");
                onComplete();
            }
            
            function onSignUpError(error:String, httpStatus:int):void
            {
                // confirmation mail was sent. Now activate player.
                activatePlayerThroughEmail(email, onConfirmationComplete, onConfirmationError);
            }
            
            function onConfirmationComplete():void
            {
                Player.loginWithEmailAndPassword(email, password, true, onLoginComplete, onError);
            }
            
            function onConfirmationError(error:String):void
            {
                fail("Could not activate email/password player via mail: " + error);
                onComplete();
            }
            
            function onLoginComplete(signedUpPlayer:CustomPlayer):void
            {
                // now try to store the player (a specific server version failed here)
                signedUpPlayer.save(onSaveComplete, onError);
            }
            
            function onSaveComplete():void
            {
                onComplete();
            }
            
            function onError(error:String, httpStatus:int):void
            {
                fail(error);
                onComplete();
            }
        }
    }
}

import com.gamua.flox.Player;

class CustomPlayer extends Player
{
    private var mLastName:String;
    
    public function CustomPlayer(lastName:String="unknown")
    {
        mLastName = lastName;
    }
    
    public function get lastName():String { return mLastName; }
    public function set lastName(value:String):void { mLastName = value; }
}

class CustomPlayerWithAuthId extends Player
{
    public var authId:String;
}