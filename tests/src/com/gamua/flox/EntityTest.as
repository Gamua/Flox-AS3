package com.gamua.flox
{
    import com.gamua.flox.utils.CustomEntity;
    import com.gamua.flox.utils.cloneObject;
    
    import starling.unit.UnitTest;
    
    public class EntityTest extends UnitTest
    {
        override public function setUp():void
        {
            Entity.register(Player.TYPE, Player);
            Entity.register(CustomEntity.TYPE, CustomEntity);
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
            var originalData:Object = cloneObject(localPlayer);
            
            localPlayer.save(onSaveComplete, onSaveError);

            function onSaveComplete(player:Player):void
            {
                assertEqualObjects(originalData, cloneObject(player));
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
                
                assertEqualEntities(entity, localPlayer);
                
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
        
        public function testCustomEntity(onComplete:Function):void
        {
            Constants.initFlox();
            Flox.clearCache();
            
            var testEntity:CustomEntity = new CustomEntity();
            testEntity.age = 31;
            testEntity.name = "Daniel";
            var originalData:Object = cloneObject(testEntity);
            testEntity.save(onSaveComplete, onSaveError);
            
            function onSaveComplete(entity:CustomEntity):void
            {
                assertEqualObjects(originalData, cloneObject(entity));
                Flox.clearCache();
                Entity.load(CustomEntity.TYPE, testEntity.id, onLoadComplete, onLoadError);
            }
            
            function onSaveError(error:String, transient:Boolean):void
            {
                Flox.shutdown();
                fail("Could not save custom entity: " + error);
                onComplete();
            }
            
            function onLoadComplete(entity:Entity, fromCache:Boolean):void
            {
                assertEqualEntities(entity, testEntity);
                
                Flox.shutdown();
                onComplete();
            }
            
            function onLoadError(error:String, transient:Boolean):void
            {
                Flox.shutdown();
                fail("Could not load custom entity: " + error);
                onComplete();
            }
        }
        
        public function testRefresh(onComplete:Function):void
        {
            Constants.initFlox();
            Flox.clearCache();
            
            var name:String = "Daniel";
            var age:int = 31;
            
            var testEntity:CustomEntity = new CustomEntity();
            testEntity.age = age;
            testEntity.name = name;
            var originalData:Object = cloneObject(testEntity);
            testEntity.save(onSaveComplete, onError);
            
            function onSaveComplete(entity:CustomEntity):void
            {
                assertEqualObjects(originalData, cloneObject(entity));
                entity.name = "Hugo";
                entity.age = 5;
                
                // should undo those changes
                entity.refresh(onRefreshComplete, onError);
            }
            
            function onRefreshComplete(entity:Entity, fromCache:Boolean):void
            {
                assertEqualObjects(originalData, cloneObject(entity));
                Flox.shutdown();
                onComplete();
            }
            
            function onError(error:String, transient:Boolean):void
            {
                Flox.shutdown();
                fail("Error with custom entity: " + error);
                onComplete();
            }
        }

        private function assertEqualEntities(entityA:Entity, entityB:Entity, 
                                             compareDates:Boolean=false):void
        {
            if (compareDates) assertEqualObjects(entityA, entityB);
            else
            {
                var objectA:Object = cloneObject(entityA);
                var objectB:Object = cloneObject(entityB);
                
                delete objectA["createdAt"];
                delete objectA["updatedAt"];
                delete objectB["createdAt"];
                delete objectB["updatedAt"];
                
                assertEqualObjects(objectA, objectB);
            }
        }
        
    }
}