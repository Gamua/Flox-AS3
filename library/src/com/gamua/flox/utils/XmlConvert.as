package com.gamua.flox.utils
{
    import com.hurlant.util.Base64;
    
    import flash.utils.ByteArray;
    
    import mx.formatters.DateBase;
    
    /** Class that contains static utility methods for XML serialization. */
    public class XmlConvert
    {
        /** Compresses an XML and encodes it as a Base64 String. */
        public static function serialize(object:Object, name:String, xml:XML=null):XML
        {
            var serialization:XML;
            var type:String;
            
            if      (object is int)     type = "int";
            else if (object is Number)  type = "float";
            else if (object is Boolean) type = "bool";
            else if (object is String)  type = "string";
            else                        type = "dict";
            
            if (type == "dict")
            {
                serialization = <r name={name} type={type}/>
                
                for (var propertyName:String in object)
                    serialize(object[propertyName], propertyName, serialization);
            }
            else
            {
                serialization = <r name={name} type={type}>{object.toString()}</r>;
            }
            
            if (xml == null)
                return serialization;
            else
            {
                xml.appendChild(serialization);
                return xml;
            }
        }
        
        public static function deserialize(xml:XML):Object
        {
            var type:String = xml.@type.toString();
            
            if (type == "dict")
            {
                var object:Object = {};
                
                for each (var xmlNode:XML in xml.children())
                    object[xmlNode.@name.toString()] = deserialize(xmlNode);
                    
                return object;
            }
            else if (type == "int" || type == "uint")
                return parseInt(xml.toString());
            else if (type == "float")
                return parseFloat(xml.toString());
            else if (type == "bool")
                return parseBool(xml.toString());
            else 
                return xml.toString();
        }
        
        private static function parseBool(str:String):Boolean
        {
            var value:String = str.toLowerCase();
            if (str == "true" || str == "yes" || str == "1") return true;
            else return false;
        }
        
        public static function encode(xml:XML):String
        {
            var origPrettyPrinting:Boolean = XML.prettyPrinting;
            XML.prettyPrinting = false;
            
            var data:ByteArray = new ByteArray();
            data.writeUTFBytes(xml.toXMLString());
            data.compress();
            
            XML.prettyPrinting = origPrettyPrinting;
            return Base64.encodeByteArray(data);
        }
        
        /** Parses dates that conform to the xs:DateTime format. */
        public static function dateFromString(str:String):Date
        {
            var finalDate:Date;
            
            try
            {
                var dateStr:String = str.substring(0, str.indexOf("T"));
                var timeStr:String = str.substring(str.indexOf("T")+1, str.length);
                var dateArr:Array = dateStr.split("-");
                var year:Number = Number(dateArr.shift());
                var month:Number = Number(dateArr.shift());
                var date:Number = Number(dateArr.shift());
                
                var multiplier:Number;
                var offsetHours:Number;
                var offsetMinutes:Number;
                var offsetStr:String;
                
                if (timeStr.indexOf("Z") != -1)
                {
                    multiplier = 1;
                    offsetHours = 0;
                    offsetMinutes = 0;
                    timeStr = timeStr.replace("Z", "");
                }
                else if (timeStr.indexOf("+") != -1)
                {
                    multiplier = 1;
                    offsetStr = timeStr.substring(timeStr.indexOf("+")+1, timeStr.length);
                    offsetHours = Number(offsetStr.substring(0, offsetStr.indexOf(":")));
                    offsetMinutes = Number(offsetStr.substring(offsetStr.indexOf(":")+1, offsetStr.length));
                    timeStr = timeStr.substring(0, timeStr.indexOf("+"));
                }
                else // offset is -
                {
                    multiplier = -1;
                    offsetStr = timeStr.substring(timeStr.indexOf("-")+1, timeStr.length);
                    offsetHours = Number(offsetStr.substring(0, offsetStr.indexOf(":")));
                    offsetMinutes = Number(offsetStr.substring(offsetStr.indexOf(":")+1, offsetStr.length));
                    timeStr = timeStr.substring(0, timeStr.indexOf("-"));
                }
                var timeArr:Array = timeStr.split(":");
                var hour:Number = Number(timeArr.shift());
                var minutes:Number = Number(timeArr.shift());
                var secondsArr:Array = (timeArr.length > 0) ? String(timeArr.shift()).split(".") : null;
                var seconds:Number = (secondsArr != null && secondsArr.length > 0) ? Number(secondsArr.shift()) : 0;
                
                var milliseconds:Number = (secondsArr != null && secondsArr.length > 0) ? 1000*parseFloat("0." + secondsArr.shift()) : 0; 
                var utc:Number = Date.UTC(year, month-1, date, hour, minutes, seconds, milliseconds);
                var offset:Number = (((offsetHours * 3600000) + (offsetMinutes * 60000)) * multiplier);
                finalDate = new Date(utc - offset);
                
                if (finalDate.toString() == "Invalid Date")
                    throw new Error("This date does not conform to W3CDTF.");
            }
            catch (e:Error)
            {
                var eStr:String = "Unable to parse the string [" +str+ "] into a date. ";
                eStr += "The internal error was: " + e.toString();
                throw new Error(eStr);
            }
            return finalDate;
        }
        
        /** Returns a date string formatted according to the xs:DateTime format. */		     
        public static function dateToString(d:Date):String
        {
            var date:Number = d.getUTCDate();
            var month:Number = d.getUTCMonth();
            var hours:Number = d.getUTCHours();
            var minutes:Number = d.getUTCMinutes();
            var seconds:Number = d.getUTCSeconds();
            var milliseconds:Number = d.getUTCMilliseconds();
            
            var sb:String = d.fullYearUTC.toString();
            sb += "-";
            if (month + 1 < 10) sb += "0";
            sb += month + 1;
            sb += "-";
            if (date < 10) sb += "0";
            sb += date;
            sb += "T";
            if (hours < 10) sb += "0";
            sb += hours;
            sb += ":";
            if (minutes < 10) sb += "0";
            sb += minutes;
            sb += ":";
            if (seconds < 10) sb += "0";
            sb += seconds;
            if (milliseconds > 0) sb += "." + milliseconds;
            sb += "Z"; //instead of: sb += "-00:00";
            
            return sb;
        }
    }
}
