package tests
{
    import com.gamua.flox.utils.XmlConvert;
    
    import starling.unit.UnitTest;

    public class SerializationTest extends UnitTest
    {
        // todo: test with array / vector
        
        public function testConventional():void
        {
            var original:Object = {
                "a_number": Math.PI,
                    "an_integer": 1024,
                    "a_string": "hugo ging nach hause",
                    "a_dict": {
                        "something": "apple",
                        "anything": 57.15
                    }
            };
            
            var xml:XML = XmlConvert.serialize(original, "object");            
            var copy:Object = XmlConvert.deserialize(xml);
            
            assertEqualObjects(original, copy);
        }
    }
}