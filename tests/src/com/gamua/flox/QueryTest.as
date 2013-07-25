package com.gamua.flox
{
    import com.gamua.flox.events.QueueEvent;
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.cloneObject;
    import com.gamua.flox.utils.createUID;
    import com.gamua.flox.utils.execute;
    
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
        
        public function testWhere():void
        {
            var query:Query = new Query(Player);
            
            assertEqual('dunno == 10', query.where("dunno == ?", 10), "wrong replacement");
            assertEqual('dunno == "hugo"', query.where("dunno == ?", "hugo"), "wrong replacement");
            assertEqual('dunno == true', query.where("dunno == ?", true), "wrong replacement");
            
            assertEqual('dunno == 10 AND watnot == "test"', 
                query.where("dunno == ? AND watnot == ?", 10, "test"), "wrong replacement");
            
            assertEqual('dunno == 10 AND watnot == 11', 
                query.where("dunno == ? AND watnot == 11", 10), "wrong replacement");
            
            assertEqual('dunno == 10 AND watnot == "test"', 
                query.where("dunno == ? AND watnot == ?", 10, "test", true), "wrong replacement");
            
            assertEqual('enabled == true',
                query.where("enabled == ?", true), "wrong bool replacement");
            
            var date:Date = new Date();
            var dateStr:String = DateUtil.toString(date);
            
            assertEqual('date == "' + dateStr + '"',
                query.where('date == ?', date), "wrong date replacement");
            
            var evil:String = "\" OR date != \"";
            var correctedEvil:String = query.where('date == ?', evil);
            var expectedEvil:String = "date == \"\\\" OR date != \\\"\"";
            
            assertEqual(expectedEvil, correctedEvil, "unsafe string not replaced correctly");
            
            // it must also be possible to replace a question mark with a "?" string.
            assertEqual('dunno == "?" AND x == "hugo"',
                query.where("dunno == ? AND x == ?", "?", "hugo"), 
                "question mark not replaced with question mark");
        }
        
        public function testEmptyQuery(onComplete:Function):void
        {
            var product:Product = new Product("tamagotchi", 42);
            var query:Query = new Query(Product);
            
            makeQueryTest([product], query, 1, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                assertEqualEntities(entities[0], product);
            }
        }
        
        public function testSimpleQuery(onComplete:Function):void
        {
            var name:String = createUID();
            var product:Product = new Product(name, 42);
            var query:Query = new Query(Product, "name == ?", name);
            
            makeQueryTest([product], query, 1, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                assertEqualEntities(entities[0], product);
            }
        }
        
        public function testSimpleAndQuery(onComplete:Function):void
        {
            var name:String = createUID();
            var price:int = Math.random() * 100;
            var product:Product = new Product(name, price);
            var query:Query = new Query(Product, "name == ? AND price == ?", name, price);
            
            makeQueryTest([product], query, 1, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
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
            
            var query:Query = new Query(Product, "price >= ? AND price < ?", 1, 6);
            makeQueryTest(products, query, 5, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                entities.sortOn("price");
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
            var query:Query = new Query(Product, "price >= 1 AND price < 6");
            query.limit = limit;
            assertEqual(limit, query.limit, "wrong limit");
            
            makeQueryTest(products, query, limit, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                entities.sortOn("price");
                assertEqualEntities(entities[0], products[1]);
                assertEqualEntities(entities[1], products[2]);
                assertEqualEntities(entities[2], products[3]);
            }
        }
        
        public function testOrQuery(onComplete:Function):void
        {
            var products:Array = [
                new Product("alfa", 0),
                new Product("bravo", 1),
                new Product("charlie", 2),
            ];
            
            var query:Query = new Query(Product, "name == ? OR price == 2", "bravo");
            makeQueryTest(products, query, 2, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                entities.sortOn("price");
                assertEqualEntities(entities[0], products[1]);
                assertEqualEntities(entities[1], products[2]);
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
            
            var query:Query = new Query(Product, "name > ? AND name < ?", "alfa", "delta");
            makeQueryTest(products, query, 2, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                entities.sortOn("price");
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
            
            var query:Query = new Query(Product, "date > ? AND date < ?", 
                                        products[0].date, products[3].date);
            
            makeQueryTest(products, query, 2, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                entities.sortOn("date");
                assertEqualEntities(entities[0], products[1]);
                assertEqualEntities(entities[1], products[2]);
            }
        }
        
        public function testInequalityQuery(onComplete:Function):void
        {
            var products:Array = [
                new Product("alfa", 0),
                new Product("bravo", 1)
            ];

            var query:Query = new Query(Product, "price != 1");
            makeQueryTest(products, query, 1, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                assertEqualEntities(entities[0], products[0]);
            }
        }
        
        public function testGroupedQuery(onComplete:Function):void
        {
            var products:Array = [
                new Product("alfa", 0),
                new Product("alfa", 1),
                new Product("bravo", 1),
                new Product("charlie", 1),
                new Product("bravo", 2)
            ];
            
            var query:Query = new Query(Product, 
                "(name == ? OR name == ?) AND (price == 1)", "alfa", "bravo");
            makeQueryTest(products, query, 2, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                entities.sortOn("name");
                assertEqualEntities(entities[0], products[1]);
                assertEqualEntities(entities[1], products[2]);
            }
        }
        
        public function testInjectionQuery(onComplete:Function):void
        {
            var name:String = ' OR name == "hugo"';
            var product0:Product = new Product("hugo", 10);
            var product1:Product = new Product(name, 11);
            
            var query:Query = new Query(Product, "name == ?", name);
            makeQueryTest([product0, product1], query, 1, checkResult, onComplete);
            
            function checkResult(entities:Array):void
            {
                assertEqualEntities(entities[0], product1);
            }
        }
        
        public function testOffsetReliability(onComplete:Function):void
        {
            var abort:Boolean = false;
            var firstResults:Array;
            var products:Array = [
                new Product("alpha",   Math.random() * 10),
                new Product("beta",    Math.random() * 10),
                new Product("gamma",   Math.random() * 10),
                new Product("delta",   Math.random() * 10),
                new Product("epsilon", Math.random() * 10),
                new Product("zeta",    Math.random() * 10)
                ];
            
            var query:Query = new Query(Product, "price > 8");
            var remainingTests:int;
            var expectedCount:int = 
                products.filter(function(p:Product, ...r):Boolean { return p.price < 8; }).length;
            
            for each (var product:Product in products)
                product.saveQueued();
                
            Flox.addEventListener(QueueEvent.QUEUE_PROCESSED, onProductsSaved);
            
            function onProductsSaved(event:*):void
            {
                Flox.removeEventListener(QueueEvent.QUEUE_PROCESSED, onProductsSaved);
                executeQueryWithRetries(query, expectedCount, onFirstQueryComplete, onError);
            }
            
            function onFirstQueryComplete(results:Array):void
            {
                remainingTests = results.length;
                firstResults = results;
                
                for (var i:int=0; i<results.length; ++i)
                    executeQueryWithLimitAndOffset(1, i, results[i]);
            }
            
            function executeQueryWithLimitAndOffset(limit:int, offset:int, 
                                                    expectedResult:Object):void
            {
                query.limit = limit;
                query.offset = offset;
                
                query.find(function(results:Array):void
                {
                    if (!abort)
                    {
                        assertEqual(1, results.length);
                        assertEqualObjects(results[0], expectedResult);
                        if (--remainingTests == 0) onComplete();
                    }
                }, onError);
            }
            
            function onError(error:String):void
            {
                if (!abort)
                {
                    abort = true;
                    fail("could not execute query. Error: " + error);
                    onComplete();
                }
            }
        }
        
        private function makeQueryTest(inputEntities:Array, query:Query, expectedCount:int,
                                       onResult:Function, onComplete:Function):void
        {
            Flox.addEventListener(QueueEvent.QUEUE_PROCESSED, onProductsSaved);
            
            for each (var entity:Entity in inputEntities)
                entity.saveQueued();
            
            function onProductsSaved(event:QueueEvent):void
            {
                Flox.removeEventListener(QueueEvent.QUEUE_PROCESSED, onProductsSaved);
                
                if (event.success)
                {
                    executeQueryWithRetries(query, expectedCount, onQueryComplete, onQueryError);
                }
                else
                {
                    fail("could not save entities: " + event.error);
                    onComplete();
                }
            }
            
            function onQueryComplete(outputEntities:Array):void
            {
                assert(outputEntities is Array);
                execute(onResult, outputEntities);
                onComplete();
            }
            
            function onQueryError(error:String, httpStatus:int):void
            {
                fail("could not execute query. Error: " + error);
                onComplete();
            }
        }
        
        private function executeQueryWithRetries(query:Query, expectedCount:int, 
                                                 onComplete:Function, onError:Function,
                                                 retries:int=10):void
        {
            var tries:int = 0;
            query.find(onQueryComplete, onError);
            
            function onQueryComplete(results:Array):void
            {
                if (results == null)
                {
                    onError("query returned 'null' result");
                }
                if (results.length != expectedCount)
                {
                    if (++tries > retries)
                    {
                        trace("  retrying (" + tries + "/" + retries + ") ...");
                        query.find(onQueryComplete, onError);
                    }
                    else
                    {
                        onError("wrong number of entities returned: " + results.length);
                    }
                }
                else onComplete(results);
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