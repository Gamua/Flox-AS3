package com.gamua.flox
{
    import starling.unit.UnitTest;
    
    public class PlayerTest extends UnitTest
    {
        public function testCustomPlayer():void
        {
            var player:CustomPlayer = new CustomPlayer("Baggins");
            assertEqual(player.type, ".player");
        }
        
        public function testGuestLogin():void
        {
            Constants.initFlox();
            
            var defaultGuest:Player = Player.local;
            assertNotNull(defaultGuest);
            assertNotNull(defaultGuest.id);
            assertEqual(".player", defaultGuest.type);
            assertEqual(AuthenticationType.GUEST, defaultGuest.authType);
            
            Player.login();
            var newGuest:Player = Player.local;
            assert(defaultGuest != newGuest);
            assert(defaultGuest.id != newGuest.id);
            
            Flox.shutdown();
        }
        
        public function testLoginCustomPlayer():void
        {
            Flox.playerClass = CustomPlayer;
            Constants.initFlox();
            
            var player:CustomPlayer = Player.local as CustomPlayer;
            var playerID:String = player.id;
            var lastName:String = "Baggins";
            player.lastName = lastName;
            
            assertNotNull(player);
            
            Flox.shutdown();
            
            Constants.initFlox();
            assertEqual(playerID, Player.local.id);
            assertEqual(lastName, (Player.local as CustomPlayer).lastName);
            
            Flox.shutdown();
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