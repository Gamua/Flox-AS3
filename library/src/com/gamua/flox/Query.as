// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.HttpMethod;
    import com.gamua.flox.utils.createURL;
    import com.gamua.flox.utils.execute;
    import com.gamua.flox.utils.formatString;

    /** The Query class allows you to retrieve entities from the server by narrowing down
     *  the results with certain constraints. The system works similar to SQL "select" statements.
     * 
     *  <p>Before you can make a query, you have to create indices that match the query. You can
     *  do that in the online interface. An index has to contain all the properties that are 
     *  referenced in the constraints.</p>
     * 
     *  <p>Here is an example of how you can execute a Query with Flox. This query requires 
     *  an index containing both "level" and "score" properties.</p>
     *  <pre>
     *  var query:Query = new Query(Player);
     *  query.where("level == ? and score > ?", "tutorial", 500);
     *  query.find(function onComplete(players:Array):void
     *  {
     *      // the 'players' array contains all players in the 'tutorial' level
     *      // with a score higher than 500. 
     *  },
     *  function onError(error:String):void
     *  {
     *      trace("something went wrong: " + error);
     *  });</pre>
     */  
    public class Query
    {
        private var mClass:Class;
        private var mOffset:int;
        private var mLimit:int;
        private var mWhere:String;
        
        /** Create a new query that will search within the given Entity type. Optionally, you
         *  pass the constraints in the same way as in the "where" method. */
        public function Query(entityClass:Class, constraints:String=null, ...args)
        {
            mClass = entityClass;
            mOffset = 0;
            mLimit = 50;
            
            if (constraints)
            {
                args.unshift(constraints);
                where.apply(this, args);
            }
        }
        
        /** You can narrow down the results of the query with an SQL like where-clause. The
         *  constraints string supports the following comparison operators: 
         *  "==, &gt;, &gt;=, &lt;, &lt;=, !=".
         *  You can combine constraints using "AND" and "OR"; construct logical groups with 
         *  round brackets.
         *  
         *  <p>To simplify creation of the constraints string, you can use questions marks ("?")
         *  as placeholders. They will be replaced one by one with the additional parameters you
         *  pass to the method, while making sure their format is correct (e.g. it surrounds
         *  Strings with quotations marks). Here is an example:</p>
         *  <pre>
         *  query.where("name == ? AND score > ?", "thomas", 500); 
         *  // -> 'name == "thomas" AND score == 500'</pre>
         *  
         *  <p>Note that subsequent calls to this method will replace preceding constraints.</p>
         *  
         *  @returns the final constraints-string that will be passed to the server.
         */ 
        public function where(constraints:String, ...args):String
        {
            for each (var arg:* in args)
            {
                if (arg is Date) arg = DateUtil.toString(arg);
                var format:String = (arg is Number || arg is Boolean) ? '{0}' : '"{0}"';
                var replacement:String = formatString(format, arg);
                constraints = constraints.replace("?", replacement);
            }
        
            mWhere = constraints;
            return constraints;
        }
        
        /** Executes the query and passes the list of results to the "onComplete" callback. 
         *  Beware: if you haven't created the required indices, the result array will always be
         *  empty!
         *  
         *  @param onComplete: a callback with the form: 
         *                     <pre>onComplete(entities:Array):void;</pre>
         *  @param onError:    a callback with the form:
         *                     <pre>onError(error:String, httpStatus:int):void;</pre>
         */
        public function find(onComplete:Function, onError:Function):void
        {
            var entities:Array = [];
            var numResults:int = -1;
            var numLoaded:int = 0;
            var abort:Boolean = false;
            var service:RestService = Flox.service;
            
            var path:String = createURL("entities", type);
            var data:Object = { where: mWhere, offset: mOffset, limit: mLimit };
            
            Flox.service.request(HttpMethod.POST, path, data, onRequestComplete, onError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                var results:Array = body as Array;
                numResults = results ? results.length : 0;
                
                for (var i:int=0; i<numResults; ++i)
                {
                    var result:Object = results[i];
                    loadEntity(i, result.id, result.eTag);
                }
                
                if (numResults == 0) finish();
            }
            
            function loadEntity(position:int, id:String, eTag:String):void
            {
                var entity:Entity = Entity.fromCache(type, id, eTag); 
                
                if (entity) addEntity(position, entity);
                else Entity.load(mClass, id, function(e:Entity):void { addEntity(position, e); }, 
                                             onLoadError);
            }
            
            function onLoadError(error:String, httpStatus:int):void
            {
                if (!abort)
                {
                    abort = true;
                    execute(onError, error, httpStatus);
                }
            }
            
            function addEntity(position:int, entity:Entity):void
            {
                entities[position] = entity;
                ++numLoaded;
                if (numLoaded == numResults) finish();
            }
            
            function finish():void
            {
                if (!abort) execute(onComplete, entities);
            }
        }
        
        /** Indicates the entity type that is searched. */
        public function get type():String { return Entity.getType(mClass); }
        
        /** Indicates the offset of the results returned by the query. @default 0 */
        public function get offset():int { return mOffset; }
        public function set offset(value:int):void { mOffset = value; }
        
        /** Indicates the maximum number of returned entities. @default 50 */
        public function get limit():int { return mLimit; }
        public function set limit(value:int):void { mLimit = value; }
    }
}