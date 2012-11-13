package com.gamua.flox
{
    import starling.unit.UnitTest;
    
    public class PersistentQueueTest extends UnitTest
    {
        private static const QUEUE_NAME:String = "queue-name";
        
        public override function setUp():void
        {
            (new PersistentQueue(QUEUE_NAME)).clear();
        }
        
        public function testEnqueueAndDequeue():void
        {
            var queue:PersistentQueue = new PersistentQueue(QUEUE_NAME);
            
            var object0:Object = { "string": "hugo", "number": 0 };
            var object1:Object = { "string": "tina", "number": 1 };
            var object2:Object = { "string": "anna", "number": 2 };
            
            queue.enqueue(object0);
            queue.enqueue(object1);
            queue.enqueue(object2);
            
            assertEqualObjects(queue.peek(), object0);
            assertEqualObjects(queue.peek(), object0);
            
            assertEqualObjects(queue.dequeue(), object0);
            assertEqualObjects(queue.peek(), object1);
            
            queue.enqueue(object0);
            
            assertEqualObjects(queue.dequeue(), object1);
            assertEqualObjects(queue.peek(), object2);
            
            assertEqualObjects(queue.dequeue(), object2);
            assertEqualObjects(queue.dequeue(), object0);
            assertNull(queue.dequeue());
        }
        
        public function testPersistency():void
        {
            var queue:PersistentQueue = new PersistentQueue(QUEUE_NAME);
            
            var object0:Object = { "string": "hugo", "number": 0 };
            var object1:Object = { "string": "tina", "number": 1 };
            
            queue.enqueue(object0);
            queue.enqueue(object1);
            
            queue = new PersistentQueue(QUEUE_NAME);
            
            assertEqual(2, queue.length);
            assertEqualObjects(queue.dequeue(), object0);
            assertEqualObjects(queue.dequeue(), object1);
            assertEqualObjects(queue.dequeue(), null);
        }
        
        public function testClear():void
        {
            var queue:PersistentQueue = new PersistentQueue(QUEUE_NAME);
            queue.enqueue(1);
            queue.enqueue(2.0);
            queue.enqueue("three");
            queue.clear();
            assertEqual(queue.length, 0);
        }
    }
}