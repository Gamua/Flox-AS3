/*
 * This is a modified version of the Base64 class from the AS3 Crypto Library:
 * -> http://code.google.com/p/as3crypto/
 * 
 * 
 * Base64 - 1.1.0
 *
 * Copyright (c) 2006 Steve Webster
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions: 
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
package com.gamua.flox.utils 
{
    import flash.utils.ByteArray;
    
    /** Utility class to encode and decode data from and to Base64 format. */
    public class Base64 
    {
        private static const BASE64_CHARS:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
        
        /** helper objects */
        private static var sOutputBuilder:ByteArray    = new ByteArray();
        private static var sDataBuffer:Vector.<uint>   = new <uint>[];
        private static var sOutputBuffer:Vector.<uint> = new <uint>[]
        
        /** Encodes a given String in Base64 format. */
        public static function encode(data:String):String 
        {
            // Convert string to ByteArray
            var bytes:ByteArray = new ByteArray();
            bytes.writeUTFBytes(data);
            
            // Return encoded ByteArray
            return encodeByteArray(bytes);
        }
        
        /** Encodes a given ByteArray into a Base64 representation. */
        public static function encodeByteArray(data:ByteArray):String 
        {
            // Initialise output
            var output:String;
            
            // Rewind ByteArray
            data.position = 0;
            
            // while there are still bytes to be processed
            while (data.bytesAvailable > 0) 
            {
                var numBytes:int = data.bytesAvailable >= 3 ? 3: data.bytesAvailable;
                
                // Create new data buffer and populate next 3 bytes from data
                for (var i:uint = 0; i < numBytes; ++i) 
                    sDataBuffer[i] = data.readUnsignedByte();
                
                // Convert to data buffer Base64 character positions and 
                // store in output buffer
                sOutputBuffer[0] = ( sDataBuffer[0] & 0xfc) >> 2;
                sOutputBuffer[1] = ((sDataBuffer[0] & 0x03) << 4) | ((sDataBuffer[1]) >> 4);
                sOutputBuffer[2] = ((sDataBuffer[1] & 0x0f) << 2) | ((sDataBuffer[2]) >> 6);
                sOutputBuffer[3] =   sDataBuffer[2] & 0x3f;
                
                // If data buffer was short (i.e not 3 characters) then set
                // end character indexes in data buffer to index of '=' symbol.
                // This is necessary because Base64 data is always a multiple of
                // 4 bytes and is basses with '=' symbols.
                for (var j:uint = numBytes; j < 3; j++) 
                    sOutputBuffer[int(j + 1)] = 64;
                
                // Loop through output buffer and add Base64 characters to 
                // encoded data string for each character.
                for (var k:uint = 0; k < 4; k++)
                    sOutputBuilder.writeUTFBytes(BASE64_CHARS.charAt(sOutputBuffer[k]));
            }
            
            // Read output string
            sOutputBuilder.position = 0;
            output = sOutputBuilder.readUTFBytes(sOutputBuilder.length);
            
            // Clear temporary buffers
            sOutputBuilder.length = sOutputBuffer.length = sDataBuffer.length = 0;
            
            // Return encoded data
            return output;
        }
        
        /** Decodes a given Base64-String into the String it was created from. */
        public static function decode(data:String):String
        {
            // Decode data to ByteArray
            var bytes:ByteArray = decodeToByteArray(data);
            
            // Convert to string and return
            return bytes.readUTFBytes(bytes.length);
        }
        
        /** Decodes a given Base64-String into the ByteArray it represents. If you pass an
         *  'output' ByteArray to the function, the result will be saved into that. */
        public static function decodeToByteArray(data:String, output:ByteArray=null):ByteArray
        {
            var dataLength:int = data.length;
            
            // Initialise output ByteArray for decoded data
            if (output != null) output.length = 0;
            else output = new ByteArray();
            
            // While there are data bytes left to be processed
            for (var i:uint = 0; i < dataLength; i += 4)
            {
                // Populate data buffer with position of Base64 characters for
                // next 4 bytes from encoded data
                for (var j:uint = 0; j < 4 && i + j < dataLength; j++)
                    sDataBuffer[j] = BASE64_CHARS.indexOf(data.charAt(i + j));
                
                // Decode data buffer back into bytes
                sOutputBuffer[0] =  (sDataBuffer[0]         << 2) + ((sDataBuffer[1] & 0x30) >> 4);
                sOutputBuffer[1] = ((sDataBuffer[1] & 0x0f) << 4) + ((sDataBuffer[2] & 0x3c) >> 2);		
                sOutputBuffer[2] = ((sDataBuffer[2] & 0x03) << 6) +   sDataBuffer[3];
                
                // Add all non-padded bytes in output buffer to decoded data
                for (var k:uint = 0; k < 3; k++) 
                {
                    if (sDataBuffer[int(k+1)] == 64) break;
                    output.writeByte(sOutputBuffer[k]);
                }
            }
            
            // Rewind decoded data ByteArray
            output.position = 0;
            
            // Clear temporary buffers
            sOutputBuffer.length = sDataBuffer.length = 0;
            
            // Return decoded data
            return output;
        }
        
        /** @private */
        public function Base64() 
        {
            throw new Error("Base64 class is static container only");
        }
    }
}