package com.gamua.flox
{
    import com.gamua.flox.events.QueueEvent;
    import com.gamua.flox.utils.CustomEntity;
    import com.gamua.flox.utils.cloneObject;
    
    import starling.unit.UnitTest;
    
    public class EntityTest extends UnitTest
    {
        public function testPlayerOffline():void
        {
            var playerType:String = Entity.getType(Player);
            assertEqual(".player", playerType);
            
            var player:Player = new Player();
            assertNotNull(player.id);
            assertNotNull(player.createdAt);
            assertNotNull(player.updatedAt);
            assertEqualObjects({}, player.permissions);
            assertEqual(player.id, player.ownerID);
            assertEqual(player.authType, AuthenticationType.GUEST);
            assertEqual(player.type, playerType);
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
                Entity.fromObject(playerType, player.id, playerObject) as Player;
            
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
                Entity.load(Player, player.id, onLoadComplete, onLoadError);
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
            assertEqual(testEntity.type, Entity.getType(CustomEntity));
            
            testEntity.age = 31;
            testEntity.name = "Daniel";
            testEntity.data.nickname = "PrimaryFeather";
            var originalData:Object = cloneObject(testEntity);
            testEntity.save(onSaveComplete, onSaveError);
            
            function onSaveComplete(entity:CustomEntity):void
            {
                assertEqualObjects(originalData, cloneObject(entity));
                Flox.clearCache();
                Entity.load(CustomEntity, testEntity.id, onLoadComplete, onLoadError);
            }
            
            function onSaveError(error:String, transient:Boolean):void
            {
                Flox.shutdown();
                fail("Could not save custom entity: " + error);
                onComplete();
            }
            
            function onLoadComplete(entity:Entity, fromCache:Boolean):void
            {
                assertFalse(fromCache);
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

        public function testDestroy(onComplete:Function):void
        {
            Constants.initFlox();
            Flox.clearCache();
            
            var testEntity:CustomEntity = new CustomEntity("delete-me", 113);
            var entityID:String = testEntity.id;
            testEntity.save(onSaveComplete, onSaveOrDestroyError);
            
            function onSaveComplete(entity:CustomEntity):void
            {
                testEntity.destroy(onDestroyComplete, onSaveOrDestroyError);
            }
            
            function onDestroyComplete(entity:Entity):void
            {
                assertEqual(entityID, entity.id);
                Entity.load(CustomEntity, entityID, onLoadComplete, onLoadError);
            }
            
            function onSaveOrDestroyError(error:String, transient:Boolean):void
            {
                Flox.shutdown();
                fail("Error in save or destroy: " + error);
                onComplete();
            }
            
            function onLoadComplete(entity:Entity, fromCache:Boolean):void
            {
                Flox.shutdown();
                fail("deleted entity could be loaded");
                onComplete();
            }
            
            function onLoadError(error:String, transient:Boolean):void
            {
                Flox.shutdown();
                assertFalse(transient);
                onComplete();
            }
        }
        
        public function testLoadFromCache(onComplete:Function):void
        {
            Constants.initFlox();
            Flox.clearCache();
            
            var testEntity:CustomEntity = new CustomEntity("get-me-from-cache", int.MAX_VALUE);
            testEntity.save(onSaveComplete, onSaveError);
            
            function onSaveComplete(entity:CustomEntity):void
            {
                // now, force a problem
                Flox.service.alwaysFail = true;
                Entity.load(CustomEntity, entity.id, onLoadComplete, onLoadError);
            }
            
            function onSaveError(error:String, transient:Boolean):void
            {
                Flox.shutdown();
                fail("Error in save: " + error);
                onComplete();
            }
            
            function onLoadComplete():void
            {
                Flox.shutdown();
                fail("could load entity although 'alwaysFail' was enabled");
                onComplete();
            }
            
            function onLoadError(error:String, cachedEntity:Entity):void
            {
                assertNotNull(cachedEntity);
                assertEqualEntities(cachedEntity, testEntity);
                Flox.shutdown();
                onComplete();
            }
        }
        
        public function testSaveQueued(onComplete:Function):void
        {
            Constants.initFlox();
            Flox.clearCache();
            
            Flox.addEventListener(QueueEvent.QUEUE_PROCESSED, onQueueProcessed_Fail);
            Flox.service.alwaysFail = true;
            
            var testEntity:CustomEntity = new CustomEntity("save-through-queue", 42);
            testEntity.saveQueued();
            
            function onQueueProcessed_Fail(event:QueueEvent):void
            {
                assertFalse(event.success);
                Flox.removeEventListener(QueueEvent.QUEUE_PROCESSED, onQueueProcessed_Fail);
                Flox.addEventListener(QueueEvent.QUEUE_PROCESSED, onQueueProcessed_Success);
                Flox.service.alwaysFail = false;
                Flox.processQueue();
            }
            
            function onQueueProcessed_Success(event:QueueEvent):void
            {
                assert(event.success);
                Flox.removeEventListener(QueueEvent.QUEUE_PROCESSED, onQueueProcessed_Success);
                Entity.load(CustomEntity, testEntity.id, onLoadComplete, onLoadError);
            }
            
            function onLoadComplete(entity:CustomEntity):void
            {
                assertEqualEntities(entity, testEntity);
                Flox.shutdown();
                onComplete();
            }
            
            function onLoadError(error:String):void
            {
                fail("Could not load entity that was saved through queue");
                Flox.shutdown();
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
                
                if (objectA)
                {
                    delete objectA["createdAt"];
                    delete objectA["updatedAt"];
                }
                
                if (objectB)
                {
                    delete objectB["createdAt"];
                    delete objectB["updatedAt"];
                }
                
                assertEqualObjects(objectA, objectB);
            }
        }
    }
}