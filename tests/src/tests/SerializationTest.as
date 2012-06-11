package tests
{
    import com.gamua.flox.utils.XmlConvert;
    
    import starling.unit.UnitTest;

    public class SerializationTest extends UnitTest
    {
        // todo: test with array / vector
        
        public function testSimple():void
        {
            var original:Object = {
                "a_number": Math.PI,
                "an_integer": 1024,
                "a_string": "hugo's gone home",
                "a_dict": {
                    "something": "apple",
                    "anything": 57.15
                }
            };
            
            var xml:XML = XmlConvert.serialize(original, "object");            
            var copy:Object = XmlConvert.deserialize(xml);
            
            assertEqualObjects(original, copy);
        }
        
        public function testComplex():void
        {
            XmlConvert.registerClass(TestClass, "testClass");
            
            var t1:TestClass = new TestClass();
            t1.x = 50;
            t1.y = 200;
            t1.name = "t1";
            t1.list = [1, 2, 3];
            t1.data = { "one": 1, "two": 2 };
            
            var t2:TestClass = new TestClass();
            t2.x = 10;
            t2.y = 100;
            t2.name = "t2";
            t2.list = [4, 5, 6];
            t2.data = { "three": 3, "four": 4 };
            
            t1.child = t2;
            
            var xml:XML = XmlConvert.serialize(t1, "object");
            var copy:TestClass = XmlConvert.deserialize(xml) as TestClass;
            
            assertNotNull(copy);
            assertEqualObjects(t1, copy);
        }
    }
}

class TestClass
{
    private var mX:Number;
    private var mY:Number;
    private var mName:String;
    private var mChild:TestClass;
    private var mData:Object;
    private var mList:Array;
    
    public function TestClass():void
    { }
    
    public function get x():Number { return mX; }
    public function set x(value:Number):void { mX = value; }
    
    public function get y():Number { return mY; }
    public function set y(value:Number):void { mY = value; }
    
    public function get name():String { return mName; }
    public function set name(value:String):void { mName = value; }
    
    public function get child():TestClass { return mChild; }
    public function set child(value:TestClass):void { mChild = value; }
    
    public function get data():Object { return mData; }
    public function set data(value:Object):void { mData = value; }
    
    public function get list():Array { return mList; }
    public function set list(value:Array):void { mList = value; }
}