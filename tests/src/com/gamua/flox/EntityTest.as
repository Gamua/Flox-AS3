package com.gamua.flox
{
    import com.gamua.flox.events.QueueEvent;
    import com.gamua.flox.utils.CustomEntity;
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.HttpStatus;
    import com.gamua.flox.utils.cloneObject;
    import com.gamua.flox.utils.createUID;
    
    import flash.utils.ByteArray;
    
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
            assertEqualObjects(Access.READ, player.publicAccess);
            assertEqual(player.id, player.ownerId);
            assertEqual(player.authType, null);
            assertEqual(player.type, playerType);
            assert(player.createdAt is Date);
            assert(player.updatedAt is Date);
            
            var playerObject:Object = player.toObject();
            assert(playerObject.createdAt is String);
            assert(playerObject.updatedAt is String);
            
            var restoredPlayer:Player = 
                Entity.fromObject(playerType, player.id, playerObject) as Player;
            
            assertNotNull(restoredPlayer);
            assertEqualObjects(player, restoredPlayer);
        }
        
        public function testInvalidID():void
        {
            var entity:CustomEntity = new CustomEntity();
            entity.id = "123abcABC-_";
            
            try
            {
                entity.id = "abc!$def";
                fail("Entity excepted invalid id");
            }
            catch (e:Error) { }
        }
        
        public function testDateSerialization():void
        {
            // dates should be serialized into XMLDateTime format.
            
            var entity:CustomEntity = new CustomEntity("hugo", 12);
            var entityObject:Object = entity.toObject();
            
            assertEqual(DateUtil.toString(entity.birthday), entityObject.birthday);
            
            var restoredEntity:CustomEntity = Entity.fromObject(
                Entity.getType(CustomEntity), entity.id, entityObject) as CustomEntity;
            
            assertNotNull(restoredEntity);
            assertEqualObjects(entity, restoredEntity);
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
            
            var currentPlayer:Player = Flox.currentPlayer;
            var originalData:Object = cloneObject(currentPlayer);
            
            currentPlayer.save(onSaveComplete, onSaveError);

            function onSaveComplete(player:Player):void
            {
                assertEqualEntities(originalData, player);
                if (!useCache) Flox.clearCache();
                Entity.load(Player, player.id, onLoadComplete, onLoadError);
            }
            
            function onSaveError(error:String, httpStatus:int):void
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
                assertNotNull(entity.publicAccess);
                assertEqualObjects(entity.publicAccess, currentPlayer.publicAccess);
                
                assertEqualEntities(entity, currentPlayer);
                
                Flox.shutdown();
                onComplete();
            }
            
            function onLoadError(error:String, httpStatus:int, cachedEntity:Entity):void
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
            assertEqual(Access.NONE, testEntity.publicAccess);
            
            testEntity.age = 31;
            testEntity.name = "Daniel";
            testEntity.data.nickname = "PrimaryFeather";
            testEntity.publicMember = "test";
            
            var originalData:Object = cloneObject(testEntity);
            testEntity.save(onSaveComplete, onSaveError);
            
            function onSaveComplete(entity:CustomEntity):void
            {
                assertEqualEntities(originalData, entity);
                Flox.clearCache();
                Entity.load(CustomEntity, testEntity.id, onLoadComplete, onLoadError);
            }
            
            function onSaveError(error:String, httpStatus:int):void
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
            
            function onLoadError(error:String, httpStatus:int):void
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
                assertEqualEntities(originalData, entity);
                entity.name = "Hugo";
                entity.age = 5;
                
                // should undo those changes
                entity.refresh(onRefreshComplete, onError);
            }
            
            function onRefreshComplete(entity:Entity, fromCache:Boolean):void
            {
                assertEqualEntities(originalData, entity);
                Flox.shutdown();
                onComplete();
            }
            
            function onError(error:String, httpStatus:int):void
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
            
            function onSaveOrDestroyError(error:String, httpStatus:int):void
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
            
            function onLoadError(error:String, httpStatus:int):void
            {
                Flox.shutdown();
                assertEqual(HttpStatus.NOT_FOUND, httpStatus, "wrong http status");
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
            
            function onSaveError(error:String, httpStatus:int):void
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
            
            function onLoadError(error:String, httpStatus:int, cachedEntity:Entity):void
            {
                assertNotNull(cachedEntity);
                assertEqualEntities(cachedEntity, testEntity);
                Flox.shutdown();
                onComplete();
            }
        }
        
        public function testSaveDestroyLoad(onComplete:Function):void
        {
            Constants.initFlox();
            Player.logout();
            
            var entity:CustomEntity = new CustomEntity("Garfield", 6);
            entity.save(onSaveComplete, onError);
            
            function onSaveComplete():void
            {
                entity.destroy(onDestroyComplete, onError);
            }
            
            function onDestroyComplete():void
            {
                Entity.load(CustomEntity, entity.id, onLoadComplete, onError);
            }
            
            function onLoadComplete():void
            {
                fail("could load deleted entity");
                Flox.shutdown();
                onComplete();
            }
            
            function onError(error:String, httpStatus:int, cachedEntity:Entity):void
            {
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
        
        public function testLoadFromCacheAfterSavingQueued(onComplete:Function):void
        {
            Constants.initFlox();
            
            Flox.clearCache();
            Flox.service.alwaysFail = true;
            Flox.addEventListener(QueueEvent.QUEUE_PROCESSED, onQueueProcessed);
            
            var testEntity:CustomEntity = new CustomEntity("get-me-from-cache", Math.random() * 10000);
            testEntity.saveQueued();
            
            function onQueueProcessed(event:QueueEvent):void
            {
                assertFalse(event.success);
                Flox.removeEventListener(QueueEvent.QUEUE_PROCESSED, onQueueProcessed);
                Entity.load(CustomEntity, testEntity.id, onLoadComplete, onLoadError);
            }
            
            function onLoadComplete():void
            {
                Flox.shutdown();
                fail("could load entity although 'alwaysFail' was enabled");
                onComplete();
            }
            
            function onLoadError(error:String, httpStatus:int, cachedEntity:Entity):void
            {
                assertNotNull(cachedEntity);
                assertEqualEntities(cachedEntity, testEntity);
                Flox.shutdown();
                onComplete();
            }
        }
        
        public function testDatesAreUpdatedOnSave(onComplete:Function):void
        {
            Constants.initFlox();
            Flox.clearCache();
            
            var origCreatedAt:Date;
            var origUpdatedAt:Date;
            var testEntity:CustomEntity = new CustomEntity("check-dates", Math.random() * 100);
            testEntity.save(onSaveComplete, onError);
            
            function onSaveComplete(entity:CustomEntity):void
            {
                origCreatedAt = entity.createdAt;
                origUpdatedAt = entity.updatedAt;
                Flox.clearCache(); // force reload from server
                
                testEntity.name = "modified";
                testEntity.save(onUpdateComplete, onError);
            }
            
            function onUpdateComplete(entity:CustomEntity):void
            {
                assertEqual(DateUtil.toString(origCreatedAt), DateUtil.toString(entity.createdAt),
                            "createdAt was modified on save");
                assert(DateUtil.toString(origUpdatedAt) != DateUtil.toString(entity.updatedAt),
                       "updatedAt was not modified");
                
                Flox.shutdown();
                onComplete();
            }
            
            function onError(error:String):void
            {
                fail("Error while saving or loading entity: " + error);
                Flox.shutdown();
                onComplete();
            }
        }
        
        public function testDatesAreUpdatedOnSaveQueued(onComplete:Function):void
        {
            Constants.initFlox();
            Flox.clearCache();
            Flox.addEventListener(QueueEvent.QUEUE_PROCESSED, onQueueProcessed);
            
            var testEntity:CustomEntity = new CustomEntity("check-dates-2", Math.random() * 100);
            testEntity.saveQueued();
            
            function onQueueProcessed(event:QueueEvent):void
            {
                Flox.removeEventListener(QueueEvent.QUEUE_PROCESSED, onQueueProcessed);
                assert(event.success, "event queue not processed successfully");
                Entity.load(CustomEntity, testEntity.id, onLoadComplete, onLoadError);
            }
            
            function onLoadComplete(entity:CustomEntity):void
            {
                assertEqual(DateUtil.toString(entity.createdAt), DateUtil.toString(testEntity.createdAt),
                    "createdAt was not updated with server time on saveQueued");
                assertEqual(DateUtil.toString(entity.updatedAt), DateUtil.toString(testEntity.updatedAt),
                    "updatedAt was not updated with server time on saveQueued");
                
                Flox.shutdown();
                onComplete();
            }
            
            function onLoadError(error:String):void
            {
                fail("Error while loading entity: " + error);
                Flox.shutdown();
                onComplete();
            }
        }
        
        public function testLoadFromCacheAfterErrorWithQueue(onComplete:Function):void
        {
            Constants.initFlox();
            Flox.clearCache();
            Flox.service.alwaysFail = true;
            
            var testEntity:CustomEntity = new CustomEntity("Luke Skywalker", 10);
            testEntity.saveQueued();
            
            testEntity.age = 15;
            testEntity.saveQueued();
            
            testEntity.age = 20;
            testEntity.saveQueued();
            
            Entity.load(CustomEntity, testEntity.id, onLoadComplete, onLoadError);
            
            function onLoadComplete():void
            {
                Flox.shutdown();
                fail("could load entity although 'alwaysFail' was enabled");
                onComplete();
            }
            
            function onLoadError(error:String, httpStatus:int, cachedEntity:Entity):void
            {
                assertNotNull(cachedEntity, "didn't received entity from cache");
                assertEqualEntities(testEntity, cachedEntity, "wrong cache contents");
                Flox.shutdown();
                onComplete();
            }
        }
        
        public function testLoadNonExistingEntity(onComplete:Function):void
        {
            Constants.initFlox();
            Flox.clearCache();
            
            Entity.load(CustomEntity, "nonexisting-virtual-friend", onLoadComplete, onLoadError);
            
            function onLoadComplete():void
            {
                Flox.shutdown();
                fail("could load non-existing entity");
                onComplete();
            }
            
            function onLoadError(error:String, httpStatus:int, cachedEntity:Entity):void
            {
                Flox.shutdown();
                assertNull(cachedEntity, "cache of non-existing entity was NOT null");
                onComplete();
            }
        }
        
        public function testSaveHugeEntity(onComplete:Function):void
        {
            Constants.initFlox();
            
            var size:int = 100000;
            var bytes:ByteArray = new ByteArray();
            var string:String = "This is one part of a very long String. ";
            var numRepetitions:int = size / string.length;
            
            for (var i:int=0; i<numRepetitions; ++i)
                bytes.writeUTFBytes(createUID(string.length));
            
            bytes.position = 0;
            
            var entity:CustomEntity = new CustomEntity();
            entity.data = bytes.readUTFBytes(numRepetitions * string.length);
            entity.save(onSaveComplete, onSaveError);
            
            bytes.clear();
            
            function onSaveComplete(entity:CustomEntity):void
            {
                entity.destroy(onDestroyComplete, onDestroyError);
            }
            
            function onSaveError(error:String, httpStatus:int):void
            {
                fail("Could not save huge entity: " + error);
                Flox.shutdown();
                onComplete();
            }
            
            function onDestroyComplete():void
            {
                Flox.shutdown();
                onComplete();
            }
            
            function onDestroyError(error:String):void
            {
                fail("Could not delete huge entity: " + error);
                Flox.shutdown();
                onComplete();
            }
        }
        
        private function assertEqualEntities(entityA:Object, entityB:Object, 
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