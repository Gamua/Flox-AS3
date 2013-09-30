/*
 * This is a modified version of the SHA256 class from the AS3 Crypto Library:
 * -> http://code.google.com/p/as3crypto/
 * 
 * 
 * Copyright (c) 2007 Henri Torgemane
 * All Rights Reserved.
 *
 * MD5, SHA1, and SHA256 are derivative works (http://pajhome.org.uk/crypt/md5/)
 * Those are Copyright (c) 1998-2002 Paul Johnston & Contributors (paj@pajhome.org.uk)
 *
 * SHA256 is a derivative work of jsSHA2 (http://anmar.eu.org/projects/jssha2/)
 * jsSHA2 is Copyright (c) 2003-2004 Angel Marin (anmar@gmx.net)
 *
 * Base64 is copyright (c) 2006 Steve Webster (http://dynamicflash.com/goodies/base64)
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list 
 * of conditions and the following disclaimer. Redistributions in binary form must 
 * reproduce the above copyright notice, this list of conditions and the following 
 * disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * Neither the name of the author nor the names of its contributors may be used to endorse
 * or promote products derived from this software without specific prior written permission.
 *
 * THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND, 
 * EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY 
 * WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  
 *
 * IN NO EVENT SHALL TOM WU BE LIABLE FOR ANY SPECIAL, INCIDENTAL,
 * INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND, OR ANY DAMAGES WHATSOEVER
 * RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER OR NOT ADVISED OF
 * THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF LIABILITY, ARISING OUT
 * OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */
package com.gamua.flox.utils
{
    import flash.utils.ByteArray;
    import flash.utils.Endian;

    /** Utility class providing SHA-256 hashing. */
    public class SHA256
    {
        private static const HASH_SIZE:int = 32;
        
        private static const K:Array = [
            0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4,
            0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 
            0x9bdc06a7, 0xc19bf174,	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 
            0x4a7484aa, 0x5cb0a9dc, 0x76f988da,	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 
            0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc,
            0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,	0xa2bfe8a1, 0xa81a664b,
            0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,	0x19a4c116,
            0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
            0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 
            0xc67178f2];
        
        private static const H:Array = [
            0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 
            0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    	];
        
        /** Helper variables. */
        private static const sInputBytes:ByteArray  = new ByteArray();
        private static const sOutputBytes:ByteArray = new ByteArray();
        
        /** @private */
        public function SHA256()
        {
            throw new Error("SHA256 is static container only");
        }
        
        /** Creates the SHA-256 hash of the String and returns its Base64 representation. */
        public static function hashString(src:String):String
        {
            var result:String;
            sInputBytes.writeUTFBytes(src);
            hash(sInputBytes, sOutputBytes);
            result = Base64.encodeByteArray(sOutputBytes);
            sInputBytes.length = sOutputBytes.length = 0;
            return result;
        }
        
        /** Creates the SHA-256 hash of the String. If you pass an 'output' ByteArray to the
         *  function, the result will be saved into that. */
        public static function hash(src:ByteArray, output:ByteArray=null):ByteArray
        {
            if (output == null) output = new ByteArray();
            else output.position = 0;
            
            var savedLength:uint = src.length;
            var savedEndian:String = src.endian;
            var len:uint = savedLength * 8;
            var a:Array = [];
            
            src.endian = Endian.BIG_ENDIAN;
            
            // pad to nearest int.
            while (src.length % 4 != 0)
                src[src.length] = 0;
            
            // convert ByteArray to an array of uint
            src.position = 0;
            
            for (var i:uint=0; i<src.length; i+=4)
                a.push(src.readUnsignedInt());
            
            var h:Array = core(a, len);
            var words:uint = HASH_SIZE / 4;
            
            for (i=0; i<words; i++)
                output.writeUnsignedInt(h[i]);
            
            // unpad, to leave the source untouched.
            src.length = savedLength;
            src.endian = savedEndian;
            
            return output;
        }
        
        /** The main SHA256 worker. */
        private static function core(x:Array, len:uint):Array 
        {
            // append padding
            x[len >> 5] |= 0x80 << (24 - len % 32);
            x[((len + 64 >> 9) << 4) + 15] = len;
            
            var w:Array = [];
            var a:uint = H[0];
            var b:uint = H[1];
            var c:uint = H[2];
            var d:uint = H[3];
            var e:uint = H[4];
            var f:uint = H[5];
            var g:uint = H[6];
            var h:uint = H[7];
            
            for (var i:uint=0, xl:uint=x.length; i < xl; i += 16)
            {
                var olda:uint = a;
                var oldb:uint = b;
                var oldc:uint = c;
                var oldd:uint = d;
                var olde:uint = e;
                var oldf:uint = f;
                var oldg:uint = g;
                var oldh:uint = h;
                
                for (var j:uint=0; j<64; j++)
                {
                    if (j<16)
                        w[j] = x[i+j] || 0;
                    else
                    {
                        var s0:uint = rrol(w[j-15],  7) ^ rrol(w[j-15], 18) ^ (w[j-15] >>> 3);
                        var s1:uint = rrol(w[j- 2], 17) ^ rrol(w[j- 2], 19) ^ (w[j- 2] >>> 10);
                        w[j] = w[j - 16] + s0 + w[j-7] + s1;
                    }
                    
                    var t2:uint = (rrol(a, 2) ^ rrol(a, 13) ^ rrol(a, 22)) + ((a&b) ^ (a&c) ^ (b&c));
                    var t1:uint = h + (rrol(e, 6) ^ rrol(e, 11) ^ rrol(e, 25)) + ((e&f) ^ (g&~e)) + K[j] + w[j];
                    
                    h = g;
                    g = f;
                    f = e;
                    e = d + t1;
                    d = c;
                    c = b;
                    b = a;
                    a = t1 + t2;
                }
                
                a += olda;
                b += oldb;
                c += oldc;
                d += oldd;
                e += olde;
                f += oldf;
                g += oldg;
                h += oldh;
            }
            
            return [ a, b, c, d, e, f, g, h ];
        }
        
        /** Bitwise rotate a 32-bit number to the right. */
        private static function rrol(num:uint, cnt:uint):uint
        {
            return (num << (32-cnt)) | (num >>> cnt);
        }
    }
}