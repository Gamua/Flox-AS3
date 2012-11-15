package com.gamua.flox
{
    import starling.unit.UnitTest;
    
    public class EntityTest extends UnitTest
    {
        override public function setUp():void
        {
            Entity.register(Player.TYPE, Player);
        }
        
        public function testPlayerOffline():void
        {
            var player:Player = new Player();
            
            assertNotNull(player.id);
            assertNotNull(player.createdAt);
            assertNotNull(player.updatedAt);
            assertEqualObjects({}, player.permissions);
            assertEqual(player.id, player.ownerID);
            assertEqual(player.authType, AuthenticationType.GUEST);
            assertEqual(player.type, Player.TYPE);
            assert(player.displayName.search(/^Guest-\d{1,4}$/) == 0);
            assert(player.createdAt is Date);
            assert(player.updatedAt is Date);
            
            var playerObject:Object = player.toObject();
            
            assert("ownerId" in playerObject);
            assertFalse("ownerID" in playerObject);
            assert("authId" in playerObject);
            assertFalse("authID" in playerObject);
            assert(playerObject.createdAt is String);
            assert(playerObject.updatedAt is String);
            
            var restoredPlayer:Player = 
                Entity.fromObject(Player.TYPE, player.id, playerObject) as Player;
            
            assertNotNull(restoredPlayer);
            assertEqualObjects(player, restoredPlayer);
        }
    }
}