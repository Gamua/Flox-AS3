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
            assert(Entity.getIndex(Product, "group"));
            assert(!Entity.getIndex(Product, "name"));
            
            Entity.setIndex(Product, "name");
            Entity.setIndex(Product, "price", false);
            
            assert(Entity.getIndex(Product, "name"));
            assert(!Entity.getIndex(Product, "price"));
            
            // undo changes
            Entity.setIndex(Product, "name", false);
            Entity.setIndex(Product, "price");
        }
        
        public function testQuery1(onComplete:Function):void
        {
            var group:String = createUID();
            var product:Product = new Product("zulu", 26, group);
            var queryOptions:Object = {
                where: { "group": group }
            };
            
            makeQuery([product], [product], queryOptions, onComplete); 
        }
        
        public function testQuery2(onComplete:Function):void
        {
            // to get only the entities of this test back, we add a random 'group' identifier.
            var group:String = createUID();
            var products:Array = [
                new Product("alfa", 0, group),
                new Product("bravo", 1, group),
                new Product("charlie", 2, group),
                new Product("delta", 3, group),
                new Product("echo", 4, group)
            ];
            
            var expectedResult:Array = [ products[4], products[3] ];
            var queryOptions:Object = {
                where: { "group": group },
                orderBy: "price desc",
                limit: 2
            };
            
            makeQuery(products, expectedResult, queryOptions, onComplete); 
        }
        
        private function makeQuery(inputEntities:Array, expectedEntities:Array, 
                                  queryOptions:Object, onComplete):void
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
                assertEqual(outputEntities.length, expectedEntities.length);

                for (var i:int=0; i<expectedEntities.length; ++i)
                    assertEqualEntities(outputEntities[i], expectedEntities[i]);
                
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
    
    public function get name():String { return mName; }
    public function set name(value:String):void { mName = value; }
    
    [Indexed]
    public function get price():Number { return mPrice; }
    public function set price(value:Number):void { mPrice = value; }
    
    [Indexed]
    public function get group():String { return mGroup; }
    public function set group(value:String):void { mGroup = value; }
}