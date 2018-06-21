package com.gamua.flox
{
    import com.gamua.flox.events.QueueEvent;
    import com.gamua.flox.utils.CustomEntity;
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
            
            assertEqual('name IN ["test",2,true]',
                query.where('name IN ?', ["test", 2, true]), "wrong array replacement");
            
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

        public function testEmptyResultSet(onComplete:Function):void
        {
            var query:Query = new Query(NonExistingEntity);
            query.find(onQueryComplete, onQueryError);

            function onQueryComplete(results:Array):void
            {
                assertEqual(0, results.length);
                onComplete();
            }

            function onQueryError(error:String):void
            {
                fail("could not execute query. Error: " + error);
                onComplete();
            }
        }

        public function testEmptyQuery(onComplete:Function):void
        {
            var product:Product = new Product("tamagotchi", 42);
            var query:Query = new Query(Product);
            
            makeQueryTest([product], query, checkResult, onComplete);
            
            function checkResult(entities:Array, count:int):void
            {
                assertEqual(count, 1, "Wrong number of entities returned: " + count);
                assertEqualEntities(entities[0], product);
            }
        }
        
        public function testSimpleQuery(onComplete:Function):void
        {
            var name:String = createUID();
            var product:Product = new Product(name, 42);
            var query:Query = new Query(Product, "name == ?", name);
            
            makeQueryTest([product], query, checkResult, onComplete);
            
            function checkResult(entities:Array, count:int):void
            {
                assertEqual(count, 1, "Wrong number of entities returned: " + count);
                assertEqualEntities(entities[0], product);
            }
        }
        
        public function testSimpleAndQuery(onComplete:Function):void
        {
            var name:String = createUID();
            var price:int = Math.random() * 100;
            var product:Product = new Product(name, price);
            var query:Query = new Query(Product, "name == ? AND price == ?", name, price);
            
            makeQueryTest([product], query, checkResult, onComplete);
            
            function checkResult(entities:Array, count:int):void
            {
                assertEqual(count, 1, "Wrong number of entities returned: " + count);
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
            makeQueryTest(products, query, checkResult, onComplete);
            
            function checkResult(entities:Array, count:int):void
            {
                entities.sortOn("price");
                assert(count == 5, "Wrong number of entities returned: " + count);
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
            
            makeQueryTest(products, query, checkResult, onComplete);
            
            function checkResult(entities:Array, count:int):void
            {
                entities.sortOn("price");
                assert(count == limit, "Wrong number of entities returned: " + count);
                assertEqualEntities(entities[0], products[1]);
                assertEqualEntities(entities[1], products[2]);
                assertEqualEntities(entities[2], products[3]);
            }
        }
        
        public function testNormalQueryWithOrderBy(onComplete:Function):void
        {
            var products:Array = [
                new Product("alfa", 6),
                new Product("bravo", 4),
                new Product("charlie", 2),
                new Product("delta", 1),
                new Product("echo", 3),
                new Product("foxtrot", 5)
            ];
            
            var query:Query = new Query(Product, "price > ?", 2);
            query.orderBy = "price DESC";
            makeQueryTest(products, query, checkResult, onComplete);
            
            function checkResult(entities:Array, count:int):void
            {
                assert(count == 4, "Wrong number of entities returned: " + count);
                assertEqualEntities(entities[0], products[0]);
                assertEqualEntities(entities[1], products[5]);
                assertEqualEntities(entities[2], products[1]);
                assertEqualEntities(entities[3], products[4]);
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
            makeQueryTest(products, query, checkResult, onComplete);
            
            function checkResult(entities:Array, count:int):void
            {
                entities.sortOn("price");
                assert(count == 2, "Wrong number of entities returned: " + count);
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
            makeQueryTest(products, query, checkResult, onComplete);
            
            function checkResult(entities:Array, count:int):void
            {
                entities.sortOn("price");
                assert(count == 2, "Wrong number of entities returned: " + count);
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
            
            makeQueryTest(products, query, checkResult, onComplete);
            
            function checkResult(entities:Array, count:int):void
            {
                entities.sortOn("date");
                assert(count == 2, "Wrong number of entities returned: " + count);
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
            makeQueryTest(products, query, checkResult, onComplete);
            
            function checkResult(entities:Array, count:int):void
            {
                assert(count == 1, "Wrong number of entities returned: " + count);
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
            makeQueryTest(products, query, checkResult, onComplete);
            
            function checkResult(entities:Array, count:int):void
            {
                entities.sortOn("name");
                assert(count == 2, "Wrong number of entities returned: " + count);
                assertEqualEntities(entities[0], products[1]);
                assertEqualEntities(entities[1], products[2]);
            }
        }
        
        public function testInQuery(onComplete:Function):void
        {
            var products:Array = [
                new Product("alfa", 0),
                new Product("bravo", 1),
                new Product("charlie", 2),
                new Product("delta", 3),
                new Product("echo", 4)
            ];
            
            var query:Query = new Query(Product,
                "name IN ? OR price IN ?",
                ["alfa", "bravo", "charlie", 4, "\\\","], [1, 2, 3, true, null]);
            
            makeQueryTest(products, query, checkResult, onComplete);
            
            function checkResult(entities:Array, count:int):void
            {
                entities.sortOn("name");
                assert(count == 4, "Wrong number of entities returned: "  + count);
                assertEqualEntities(entities[0], products[0]);
                assertEqualEntities(entities[1], products[1]);
                assertEqualEntities(entities[2], products[2]);
                assertEqualEntities(entities[3], products[3]);
            }
        }
        
        public function testInjectionQuery(onComplete:Function):void
        {
            var name:String = ' OR name == "hugo"';
            var product0:Product = new Product("hugo", 10);
            var product1:Product = new Product(name, 11);
            
            var query:Query = new Query(Product, "name == ?", name);
            makeQueryTest([product0, product1], query, checkResult, onComplete);
            
            function checkResult(entities:Array, count:int):void
            {
                assert(count == 1, "Wrong number of entities returned: " + count);
                assertEqualEntities(entities[0], product1);
            }
        }
        
        public function testLotsOfCombinations(onComplete:Function):void
        {
            var products:Array = [
                new Product("one", 1, "a"),
                new Product("one", 1, "b"),
                new Product("one", 2, "a"),
                new Product("one", 2, "b"),
                new Product("two", 1, "a"),
                new Product("two", 1, "b"),
                new Product("two", 2, "a"),
                new Product("two", 2, "b")
            ];
            
            var operators:Array = [ [],
                ["=="], ["!="], [">"], ["<="],
                ["==", "=="], ["==", "!="], ["==", ">"], ["==", "<="],
                ["!=", "=="], [">", "=="], ["<=", "=="],
                ["==", "==", "=="],
                ["==", "==", "!="],
                ["==", ">", "=="],
                ["<=", "==", "=="],
                ["==", "!=", "=="],
                ["==", "==", "<="]
            ];
            
            var connectors:Array = ["AND", "OR"];
            var queries:Array = [];
            var currentQuery:Query = null;

            for each (var connector:String in connectors)
            {
                for each (var operator:Array in operators)
                {
                    var constraints:String = "";
                    
                    if (operator.length > 0)
                        constraints += "name " + operator[0] + " ?";
                    if (operator.length > 1)
                        constraints += " " + connector + " price " + operator[1] + " ?";
                    if (operator.length > 2)
                        constraints += " " + connector + " group " + operator[2] + " ?";
                    
                    // add normal query
                    pushQuery(constraints);
                    
                    // add orderBy queries; we ignore the group (otherwise we'd need too many
                    // indices) and avoid unsupported combinations.
                    if (operator.length < 3)
                    {
                        if (operator[0] != "==")
                        {
                            pushQuery(constraints, "name ASC");
                            pushQuery(constraints, "name DESC");
                        }
                        
                        if (operator[1] != "==" && operator.length == 2)
                        {
                            pushQuery(constraints, "price ASC");
                            pushQuery(constraints, "price DESC");
                        }
                    }
                }
            }
            
            for each (var product:Product in products)
                product.saveQueued();
                
            Flox.addEventListener(QueueEvent.QUEUE_PROCESSED, onProductsSaved);
            
            function pushQuery(constraints:String, orderBy:String=null):void
            {
                var query:Query = new Query(Product, constraints, "one", 1, "a");
                query.orderBy = orderBy;
                queries.push(query);
            }
            
            function onProductsSaved(event:*):void
            {
                Flox.removeEventListener(QueueEvent.QUEUE_PROCESSED, onProductsSaved);
                makeQuery();
            }
            
            function makeQuery():void
            {
                if (queries.length == 0) onComplete();
                else
                {
                    currentQuery = queries.shift() as Query;
                    //trace("query: " + currentQuery.constraints, "orderBy:", currentQuery.orderBy);
                    currentQuery.find(onQueryComplete, onQueryError);
                }
            }
            
            function onQueryComplete(products:Array):void
            {
                assert(products.length > 0);
                makeQuery();
            }
            
            function onQueryError(error:String):void
            {
                fail("error in query '" + currentQuery.constraints + "'");
                trace(error);
                onComplete();
            }
        }

        public function testQueryByID(onComplete:Function):void
        {
            var products:Array = [
                new Product("alfa", 10),
                new Product("beta", 20)
            ];
            
            var query:Query = new Query(Product, "id == ?", products[1].id);
            makeQueryTest(products, query, checkResult, onComplete);
            
            function checkResult(entities:Array, count:int):void
            {
                assert(count == 1, "Wrong number of entities returned: " + count);
                assertEqualEntities(entities[0], products[1]);
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
            
            var query:Query = new Query(Product, "price < 8");
            var remainingTests:int;
            var expectedCount:int = 
                products.filter(function(p:Product, ...r):Boolean { return p.price < 8; }).length;
            
            for each (var product:Product in products)
                product.saveQueued();
                
            Flox.addEventListener(QueueEvent.QUEUE_PROCESSED, onProductsSaved);
            
            function onProductsSaved(event:*):void
            {
                Flox.removeEventListener(QueueEvent.QUEUE_PROCESSED, onProductsSaved);
                query.find(onFirstQueryComplete, onError);
            }
            
            function onFirstQueryComplete(results:Array):void
            {
                assertEqual(expectedCount, results.length);
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
        
        public function testQueryWithHero(onComplete:Function):void
        {
            var price:int = new Date().time * 1000;
            var products:Array = [ new Product("dix", price)];
            
            Player.loginWithKey(Constants.ENABLED_HERO_KEY, onLoginComplete, onLoginError);
            
            function onLoginComplete():void
            {
                var query:Query = new Query(Product, "price == ?", price);
                makeQueryTest(products, query, checkResult, onComplete);
            }
            
            function onLoginError(error:String):void
            {
                fail("Could not login hero: " + error);
                onComplete();
            }
            
            function checkResult(entities:Array, count:int):void
            {
                assert(count == 1, "Wrong number of entities returned: " + count);
                assertEqualEntities(entities[0], products[0]);
            }
        }

        public function testFindIDs(onComplete:Function):void
        {
            var products:Array = [
                new Product("alpha",   9.99),
                new Product("beta",   99.99),
                new Product("gamma", 999.99)
            ];

            for each (var product:Product in products)
                product.saveQueued();

            var query:Query = new Query(Product, "price > 10");
            query.orderBy = "price ASC";
            query.findIDs(onQueryComplete, onQueryError);

            function onQueryComplete(entityIDs:Array):void
            {
                assertEqual(entityIDs.length, 2, "Wrong number of entity IDs returned");
                assertEqual(products[1].id, entityIDs[0], "Wrong entity ID at result #0");
                assertEqual(products[2].id, entityIDs[1], "Wrong entity ID at result #1");
                onComplete();
            }

            function onQueryError(error:String):void
            {
                fail("could not execute query. Error: " + error);
                onComplete();
            }
        }

        public function testUpdatedAtIndex(onComplete:Function):void
        {
            // This test showcases a problem described by Kelson Kugler.
            // It requires that there's an index on 'updatedAt', but no index on 'age'.

            var age:int = 0;
            var numTries:int = 1;
            var entity:CustomEntity = new CustomEntity();
            var entityID:String = entity.id;
            entity.age = age;
            entity.save(onSaveComplete, onError);

            function onSaveComplete(entity:CustomEntity):void
            {
                var updateTime:Date = entity.updatedAt;
                var before:Date = new Date(updateTime.time - 200);
                var after:Date = new Date(updateTime.time + 200);
                var query:Query = new Query(CustomEntity, "updatedAt > ? AND updatedAt < ?",
                    before, after);

                query.find(onQueryComplete, onError);
            }

            function onQueryComplete(entities:Array):void
            {
                if (entities.length == 0)
                {
                    fail("did not find Entity at try #" + numTries);
                    onComplete();
                }
                else
                {
                    var entity:CustomEntity = entities[0] as CustomEntity;
                    assertEqual(entityID, entity.id);
                    numTries++;

                    if (numTries <= 10)
                    {
                        entity.age = ++age;
                        entity.save(onSaveComplete, onError);
                    }
                    else onComplete();
                }
            }

            function onError(error:String):void
            {
                fail("error on query or save: " + error);
                onComplete();
            }
        }
        
        private function makeQueryTest(inputEntities:Array, query:Query, 
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
                    query.find(onQueryComplete, onQueryError);
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
                execute(onResult, outputEntities, outputEntities.length);
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
    
    public function get name():String { return mName; }
    public function set name(value:String):void { mName = value; }
    
    public function get price():Number { return mPrice; }
    public function set price(value:Number):void { mPrice = value; }
    
    public function get date():Date { return mDate; }
    public function set date(value:Date):void { mDate = value; }
    
    public function get group():String { return mGroup; }
    public function set group(value:String):void { mGroup = value; }
}

class NonExistingEntity extends Entity
{
    public function NonExistingEntity()
    {
        super();
    }
}