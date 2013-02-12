// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.utils
{
    /** A static helper class providing methods to convert a Date to a String or to parse a String
     *  to get a Date object. */
    public class DateUtil
    {
        /** @private */
        public function DateUtil() { throw new Error("This class cannot be instantiated."); }
        
        /** Parses dates that conform to the xs:DateTime format. */
        public static function parse(str:String):Date
        {
            if (str == null) return null;
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
        public static function toString(d:Date):String
        {
            if (d == null) return null;
            
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
            if (milliseconds > 0) 
            {
                sb += ".";
                if (milliseconds < 100) sb += "0";
                if (milliseconds < 10)  sb += "0";
                sb += milliseconds;
            }
            sb += "Z"; //instead of: sb += "-00:00";
            
            return sb;
        }
    }
}