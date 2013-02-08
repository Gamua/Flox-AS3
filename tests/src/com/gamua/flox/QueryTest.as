package com.gamua.flox
{
    import com.gamua.flox.events.QueueEvent;
    import com.gamua.flox.utils.cloneObject;
    import com.gamua.flox.utils.createUID;
    
    import starling.unit.UnitTest;
    
    use namespace flox_internal;
    
    public class QueryTest extends UnitTest
    {
        public override function setUp():void
        {
            Constants.initFlox();
        }
        
        public override function tearDown():void
        {
            Flox.shutdown();
        }
        
        public function testIndex():void
        {
            assert(Entity.getIndex(Product, "price"));
            assert(Entity.getIndex(Product, "name"));
            assert(!Entity.getIndex(Product, "group"));
            
            Entity.setIndex(Product, "group");
            Entity.setIndex(Product, "price", false);
            
            assert(Entity.getIndex(Product, "group"));
            assert(!Entity.getIndex(Product, "price"));
            
            // undo changes
            Entity.setIndex(Product, "group", false);
            Entity.setIndex(Product, "price");
        }
        
        public function testQuery1(onComplete:Function):void
        {
            var name:String = createUID();
            var product:Product = new Product(name, 26);
            var queryOptions:Object = {
                where: { name: name }
            };
            
            makeQuery([product], queryOptions, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                assertEqual(entities.length, 1);
                assertEqualEntities(entities[0], product);
            }
        }
        
        public function testQuery2(onComplete:Function):void
        {
            // to get only the entities of this test back, we add a random 'group' identifier.
            var products:Array = [
                new Product("alfa", 0),
                new Product("bravo", 1),
                new Product("charlie", 2),
                new Product("delta", 3)
            ];
            
            var limit:int = 10;
            var queryOptions:Object = {
                where: { "price >=": 1, "price <": 3 },
                limit: limit
            };
            
            makeQuery(products, queryOptions, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                assert(entities.length >= 2);
                assert(entities.length <= limit);
                
                for each (var product:Product in entities)
                {
                    assert(product.price >= 1);
                    assert(product.price < 3);
                }
            }
        }
        
        public function testQuery3(onComplete:Function):void
        {
            // to get only the entities of this test back, we add a random 'group' identifier.
            var products:Array = [
                new Product("alfa", 0),
                new Product("bravo", 1),
                new Product("charlie", 2),
                new Product("delta", 3)
            ];
            
            var limit:int = 10;
            var queryOptions:Object = {
                where: { "name >": "alfa", "name <": "delta" },
                limit: limit
            };
            
            makeQuery(products, queryOptions, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                assert(entities.length >= 2);
                assert(entities.length <= limit);
                
                for each (var product:Product in entities)
                    assert(product.name == "bravo" || product.name == "charlie");
            }
        }
        
        private function makeQuery(inputEntities:Array, queryOptions:Object, onResult:Function, 
                                   onComplete:Function):void
        {
            Flox.addEventListener(QueueEvent.QUEUE_PROCESSED, onProductsSaved);
            
            for each (var entity:Entity in inputEntities)
                entity.saveQueued();
                
            Flox.localPlayer.saveQueued();
            
            function onProductsSaved(event:QueueEvent):void
            {
                Flox.removeEventListener(QueueEvent.QUEUE_PROCESSED, onProductsSaved);
                
                if (event.success)
                {
                    Entity.find(inputEntities[0].constructor, queryOptions,
                        onQueryComplete, onQueryError);
                }
                else
                {
                    fail("could not save entities: " + event.error);
                    onComplete();
                }
            }
            
            function onQueryComplete(outputEntities:Array):void
            {
                assertNotNull(outputEntities);
                onResult(outputEntities);
                onComplete();
            }
            
            function onQueryError(error:String, httpStatus:int):void
            {
                fail("could not execute query. Error: " + error);
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

import com.gamua.flox.Entity;

class Product extends Entity
{
    private var mGroup:String;
    private var mName:String;
    private var mPrice:Number;
    
    public function Product(name:String="unknown", price:Number=0, group:String=null)
    {
        mName = name;
        mPrice = price;
        mGroup = group;
    }
    
    [Indexed]
    public function get name():String { return mName; }
    public function set name(value:String):void { mName = value; }
    
    [Indexed]
    public function get price():Number { return mPrice; }
    public function set price(value:Number):void { mPrice = value; }
    
    public function get group():String { return mGroup; }
    public function set group(value:String):void { mGroup = value; }
}