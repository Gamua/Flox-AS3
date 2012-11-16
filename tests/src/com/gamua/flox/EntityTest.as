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
        
        public function testGuestPlayer():void
        {
            Constants.initFlox();
            
            var localPlayer:Player = Flox.localPlayer;
            assertNotNull(localPlayer);
            assertEqual(AuthenticationType.GUEST, localPlayer.authType);
            assertNotNull(localPlayer.authID);
            
            Flox.shutdown();
        }
        
        public function testSaveAndLoadGuestWithCache(onComplete:Function):void
        {
            saveAndLoadGuestPlayer(true, onComplete);            
        }
        
        public function testSaveAndLoadGuestWithoutCache(onComplete:Function):void
        {
            saveAndLoadGuestPlayer(false, onComplete);            
        }
        
        public function saveAndLoadGuestPlayer(useCache:Boolean, onComplete:Function):void
        {
            Constants.initFlox();
            Flox.clearCache();
            
            var localPlayer:Player = Flox.localPlayer;
            localPlayer.save(onSaveComplete, onSaveError);

            function onSaveComplete(player:Player):void
            {
                assertEqualObjects(player, localPlayer);
                if (!useCache) Flox.clearCache();
                Entity.load(Player.TYPE, player.id, onLoadComplete, onLoadError);
            }
            
            function onSaveError(error:String, transient:Boolean):void
            {
                Flox.shutdown();
                fail("Could not save player: " + error);
                onComplete();
            }
            
            function onLoadComplete(entity:Entity, fromCache:Boolean):void
            {
                assertEqual(fromCache, useCache);
                assert(entity is Player);
                
                assertNotNull(entity.createdAt);
                assertNotNull(entity.updatedAt);
                assertNotNull(entity.permissions);
                assertEqualObjects(entity.permissions, localPlayer.permissions);
                
                // the time is replaced with server time - so, to make the following test
                // pass, we sync that part manually.
                localPlayer.createdAt = entity.createdAt;
                localPlayer.updatedAt = entity.updatedAt;
                
                assertEqualObjects(entity, localPlayer);
                
                Flox.shutdown();
                onComplete();
            }
            
            function onLoadError(error:String, transient:Boolean):void
            {
                Flox.shutdown();
                fail("Could not load player: " + error);
                onComplete();
            }
        }

    }
}