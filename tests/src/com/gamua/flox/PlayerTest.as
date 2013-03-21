package com.gamua.flox
{
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.createUID;
    import com.gamua.flox.utils.downloadTextResource;
    
    import flash.utils.setTimeout;
    
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

            var emailUser:String = "flox-unit-test-" + createUID();
            var email:String = emailUser + "@mailinator.com";
            Player.loginWithEmail(email, onLogin1Complete, onLogin1Error);
            
            function onLogin1Complete(player:Player):void
            {
                // first login should work right away.
                assertEqual(player.id, guestID); // guest has been upgraded
                assertEqual(Player.current.id, player.id);
                assertEqual(AuthenticationType.EMAIL, player.authType);
                
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
                    activatePlayerThroughEmail(email, onPlayerActivated, onMailError);
                }
                else
                {
                    fail("login via e-mail procedure did not work. Error: " + error);
                    onComplete();
                }
            }
            
            function onPlayerActivated():void
            {
                // authentication url visited! Now we can log in.
                Player.loginWithEmail(email, onLogin3Complete, onLogin3Error);
            }
            
            function onMailError(error:String, httpStatus:int):void
            {
                fail("Could not access Mailinator mails");
                onComplete();
            }
            
            function onLogin3Complete(player:Player):void
            {
                assertEqual(guestID, player.id);
                onComplete();
            }
            
            function onLogin3Error(error:String):void
            {
                fail("Login after mail activation did not work!");
                onComplete();
            }
        }
        
        private function activatePlayerThroughEmail(email:String, 
                                                    onComplete:Function, onError:Function):void
        {
            var emailUser:String = email.split("@").shift();
            var mailBoxUrl:String = "http://" + emailUser + ".mailinator.com";
            setTimeout(downloadTextResource, 2000, mailBoxUrl, onMailBoxComplete, onError);
            
            function onMailBoxComplete(htmlContents:String):void
            {
                // open up mailinator mailbox, find link to email
                var matches:Array = htmlContents.match(/<tr>.*?<a href=(.+?)>/);
                if (matches && matches.length == 2)
                    downloadTextResource("http://www.mailinator.com" + matches[1], onMailComplete, onError);
                else
                {
                    fail("Error parsing Mailinator mailbox");
                    onComplete();
                }
            }
            
            function onMailComplete(htmlContents:String):void
            {
                // find link to flox email, visit it.
                var matches:Array = htmlContents.match(
                    '<a href="(https://www.flox.cc/games/.+?/players/.+?/authorize.+?)"');
                if (matches && matches.length == 2)
                    downloadTextResource(matches[1], onAuthorizeComplete, onError);
                else
                {
                    fail("Could not find Flox link in mail");
                    onComplete();
                }
            }
            
            function onAuthorizeComplete(htmlContents:String):void
            {
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