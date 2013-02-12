package com.gamua.flox
{
    import com.gamua.flox.utils.HttpStatus;
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
            var defaultGuest:Player = Player.local;
            assertNotNull(defaultGuest);
            assertNotNull(defaultGuest.id);
            assertEqual(".player", defaultGuest.type);
            assertEqual(AuthenticationType.GUEST, defaultGuest.authType);
            
            Player.login();
            var newGuest:Player = Player.local;
            assert(defaultGuest != newGuest);
            assert(defaultGuest.id != newGuest.id);
        }
        
        public function testLoginCustomPlayer():void
        {
            var player:CustomPlayer = Player.local as CustomPlayer;
            var playerID:String = player.id;
            var lastName:String = "Baggins";
            player.lastName = lastName;
            
            assertNotNull(player);
            
            Flox.shutdown();
            
            Constants.initFlox();
            assertEqual(playerID, Player.local.id);
            assertEqual(lastName, (Player.local as CustomPlayer).lastName);
        }
        
        public function testLoginWithEmail(onComplete:Function):void
        {
            var oldPlayerID:String = Player.local.id;
            Player.logout();
            
            var guestID:String = Player.local.id;
            assert(oldPlayerID != guestID);

            var emailUser:String = "flox-unit-test-" + createUID();
            var email:String = emailUser + "@mailinator.com";
            Player.loginWithEmail(email, onLoginComplete, onError);
            
            function onLoginComplete(player:Player):void
            {
                assertEqual(player.id, guestID); // guest has been upgraded
                assertEqual(Player.local.id, player.id);
                
                // now log out again, and retry!
                Player.logout();
                Player.loginWithEmail(email, onSecondLoginComplete, onSecondLoginError);
            }
            
            function onError(error:String, httpStatus:int):void
            {
                if (httpStatus != HttpStatus.FORBIDDEN)
                {
                    fail("login via e-mail procedure did not work. Error: " + error);
                    onComplete();
                }
                else
                {
                    activatePlayerThroughEmail(email, onPlayerActivated, onMailError);
                }
            }
            
            function onPlayerActivated():void
            {
                // authentication url visited! Now we can log in.
                Player.loginWithEmail(email, onLoginComplete, onError);
            }
            
            function onMailError(error:String, httpStatus:int):void
            {
                fail("Could not access Mailinator mails");
                onComplete();
            }
            
            function onSecondLoginComplete(player:Player):void
            {
                assertEqual(guestID, player.id);
                onComplete();
            }
            
            function onSecondLoginError(error:String):void
            {
                fail("Second login did not work!");
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
                var matches:Array = htmlContents.match(/(https:\/\/www\.flox\.cc.+?)"/);
                if (matches && matches.length == 2)
                    downloadTextResource(matches[1], onAuthorizeComplete, onError);
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