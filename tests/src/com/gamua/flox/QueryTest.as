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
            Player.logout(); // create a new guest player for each test
        }
        
        public override function tearDown():void
        {
            Flox.shutdown();
        }
        
        public function testIndex():void
        {
            assert(Entity.getIndex(Product, "price"));
            assert(Entity.getIndex(Product, "name"));
            assert(Entity.getIndex(Product, "date"));
            assert(!Entity.getIndex(Product, "group"));
            
            Entity.setIndex(Product, "group");
            Entity.setIndex(Product, "price", false);
            
            assert(Entity.getIndex(Product, "group"));
            assert(!Entity.getIndex(Product, "price"));
            
            // undo changes
            Entity.setIndex(Product, "group", false);
            Entity.setIndex(Product, "price");
        }
        
        public function testSimpleQuery(onComplete:Function):void
        {
            var name:String = createUID();
            var product:Product = new Product(name, 42);
            var queryOptions:Object = {
                where: { name: name }
            };
            
            makeQuery([product], queryOptions, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                assertEqual(entities.length, 1, "Wrong number of entities returned");
                assertEqualEntities(entities[0], product);
            }
        }
        
        public function testNormalQuery(onComplete:Function):void
        {
            var products:Array = [
                new Product("alfa", 0),
                new Product("bravo", 1),
                new Product("charlie", 2),
                new Product("delta", 3),
                new Product("echo", 4),
                new Product("foxtrot", 5),
                new Product("golf", 6)
            ];
            
            var queryOptions:Object = {
                where: { "price >=": 1, "price <": 6 }
            };
            
            makeQuery(products, queryOptions, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                entities.sortOn("price");
                assert(entities.length == 5, "Wrong number of entities returned");
                assertEqualEntities(entities[0], products[1]);
                assertEqualEntities(entities[1], products[2]);
                assertEqualEntities(entities[2], products[3]);
                assertEqualEntities(entities[3], products[4]);
                assertEqualEntities(entities[4], products[5]);
            }
        }
        
        public function testNormalQueryWithLimit(onComplete:Function):void
        {
            var products:Array = [
                new Product("alfa", 0),
                new Product("bravo", 1),
                new Product("charlie", 2),
                new Product("delta", 3),
                new Product("echo", 4),
                new Product("foxtrot", 5),
                new Product("golf", 6)
            ];
            
            var limit:int = 3;
            var queryOptions:Object = {
                where: { "price >=": 1, "price <": 6 },
                limit: limit
            };
            
            makeQuery(products, queryOptions, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                assert(entities.length == limit, "Wrong number of entities returned");
            }
        }
        
        public function testStringCompareQuery(onComplete:Function):void
        {
            var products:Array = [
                new Product("alfa", 0),
                new Product("bravo", 1),
                new Product("charlie", 2),
                new Product("delta", 3)
            ];
            
            var queryOptions:Object = {
                where: { "name >": "alfa", "name <": "delta" }
            };
            
            makeQuery(products, queryOptions, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                entities.sortOn("price");
                assert(entities.length == 2, "Wrong number of entities returned");
                assertEqualEntities(entities[0], products[1]);
                assertEqualEntities(entities[1], products[2]);
            }
        }
        
        public function testDateCompareQuery(onComplete:Function):void
        {
            var products:Array = [
                new Product("alfa",    0, null, new Date(2013, 1, 1, 10,  0)),
                new Product("bravo",   1, null, new Date(2013, 1, 1, 10, 10)),
                new Product("charlie", 2, null, new Date(2013, 1, 1, 10, 20)),
                new Product("delta",   3, null, new Date(2013, 1, 1, 10, 30))
            ];
            
            var queryOptions:Object = {
                where: { "date >": products[0].date, "date <": products[3].date }
            };
            
            makeQuery(products, queryOptions, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                entities.sortOn("date");
                assert(entities.length == 2, "Wrong number of entities returned");
                assertEqualEntities(entities[0], products[1]);
                assertEqualEntities(entities[1], products[2]);
            }
        }
        
        public function testInequalityQuery(onComplete:Function):void
        {
            var products:Array = [
                new Product("alfa", 0),
                new Product("bravo", 1),
                new Product("charlie", 2),
            ];
            
            var queryOptions:Object = {
                where: { "price !=": 0, "price !=": 2 }
            };
            
            makeQuery(products, queryOptions, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                assert(entities.length == 1, "Wrong number of entities returned");
                assertEqualEntities(entities[0], products[1]);
            }
        }
        
        private function makeQuery(inputEntities:Array, queryOptions:Object, onResult:Function, 
                                   onComplete:Function):void
        {
            Flox.addEventListener(QueueEvent.QUEUE_PROCESSED, onProductsSaved);
            
            for each (var entity:Entity in inputEntities)
                entity.saveQueued();
                
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
                
                assertEqualObjects(objectA, objectB, "Entities do not match");
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
    private var mDate:Date;
    
    public function Product(name:String="unknown", price:Number=0, group:String=null, 
                            date:Date=null)
    {
        mName = name;
        mPrice = price;
        mGroup = group;
        mDate = date;
    }
    
    [Indexed]
    public function get name():String { return mName; }
    public function set name(value:String):void { mName = value; }
    
    [Indexed]
    public function get price():Number { return mPrice; }
    public function set price(value:Number):void { mPrice = value; }
    
    [Indexed]
    public function get date():Date { return mDate; }
    public function set date(value:Date):void { mDate = value; }
    
    public function get group():String { return mGroup; }
    public function set group(value:String):void { mGroup = value; }
}