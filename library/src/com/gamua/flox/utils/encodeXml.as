package com.gamua.flox.utils
{
    import com.hurlant.util.Base64;
    
    import flash.utils.ByteArray;

    /** Compresses an XML and encodes it as a Base64 String. */
    public function encodeXml(xml:XML):String
    {
        var origPrettyPrinting:Boolean = XML.prettyPrinting;
        XML.prettyPrinting = false;
        
        var data:ByteArray = new ByteArray();
        data.writeUTFBytes(xml.toXMLString());
        data.compress();
        
        XML.prettyPrinting = origPrettyPrinting;
        return Base64.encodeByteArray(data);
    }
}