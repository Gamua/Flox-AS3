package com.gamua.flox
{
    import com.gamua.flox.utils.CustomEntity;
    import com.gamua.flox.utils.DateUtil;
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
        
        public function testGuestRefresh(onComplete:Function):void
        {
            Player.current.refresh(onRefreshComplete, onError);
            
            function onRefreshComplete(player:Player):void
            {
                assertEqual(player, Player.current);
                onComplete();
            }
            
            function onError(error:String):void
            {
                fail("error refreshing player: " + error);
                onComplete();
            }
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
            var key:String = "SECRET - " + DateUtil.toString(new Date());
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
        
        private function activatePlayerThroughEmail(email:String, 
                                                    onComplete:Function, onError:Function):void
        {
            // We use Gamua's own mail server to get those activation mails.
            
            var numTries:int = 10;
            var delay:int = 1000;
            var emailUser:String = email.split("@").shift();
            var mailDumpUrl:String = "http://www.incognitek.com/maildump/" + emailUser + ".txt";
            
            setTimeout(downloadTextResource, delay, mailDumpUrl, onMailLoaded, onMailError);
            
            function onMailLoaded(rawContents:String):void
            {
                var contents:String = rawContents.replace(/=[\r\n]+/g, "").replace(/=3D/g, "=");
                
                // find link to flox email, visit it.
                var matches:Array = contents.match(
                    '<a href="(https?://(?:www.)?flox.*/games/.+?/players/.+?/authorize.+?)"');
                if (matches && matches.length == 2)
                    downloadTextResource(matches[1], onAuthorizeComplete, onError);
                else
                {
                    fail("Could not find Flox link in mail");
                    onComplete();
                }
            }
            
            function onMailError(error:String, httpStatus:int):void
            {
                if (numTries-- > 0)
                {
                    trace("  mail not yet arrived, trying again ...");
                    setTimeout(downloadTextResource, delay, mailDumpUrl, onMailLoaded, onMailError);
                }
                else
                {
                    fail("Error fetching mail");
                    onComplete();
                }
            }
            
            function onAuthorizeComplete(htmlContents:String):void
            {
                onComplete();
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