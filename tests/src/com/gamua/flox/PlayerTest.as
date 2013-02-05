package com.gamua.flox
{
    import com.gamua.flox.utils.HttpStatus;
    import com.gamua.flox.utils.createUID;
    
    import starling.unit.UnitTest;
    
    public class PlayerTest extends UnitTest
    {
        public override function setUp():void
        {
            Flox.playerClass = CustomPlayer;
            Constants.initFlox();
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
                onComplete();
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
                    var mailUrl:String = "http://" + emailUser + ".mailinator.com";
                    trace("please check the following mailbox: ", mailUrl);
                    trace("breakpoint");
                    
                    // try again
                    Player.loginWithEmail(email, onLoginComplete, onError);
                }
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