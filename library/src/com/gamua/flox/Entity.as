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
    import com.gamua.flox.utils.HttpStatus;
    import com.gamua.flox.utils.cloneObject;
    import com.gamua.flox.utils.createUID;
    import com.gamua.flox.utils.createURL;
    import com.gamua.flox.utils.describeType;
    import com.gamua.flox.utils.execute;
    import com.gamua.flox.utils.formatString;
    
    import flash.system.Capabilities;
    import flash.utils.Dictionary;
    import flash.utils.getQualifiedClassName;
    
    /** The (abstract) base class of all objects that can be stored persistently on the Flox server.
     *  
     *  <p>To create custom entities, extend this class. Subclasses have to follow a few rules:</p>
     * 
     *  <ul>
     *   <li>All constructor arguments must have default values.</li>
     *   <li>Properties always need to be readable and writable.</li>
     *   <li>Properties may have one of the following types:
     *       <code>int, Number, Boolean, String, Object, Array.</code>
     *       Support for nested entities or complex data types may be added at a later time.</li>
     *   <li>The server type of the class is defined by its name. If you want to use a different
     *       name, you can provide "Type" MetaData (see sample below).</li> 
     *  </ul>
     *  
     *  <p>Here is an example class:</p>
     *  
     *  <pre>
     *  [Type("gameState")] // optional server type; defaults to class name.
     *  public class GameState extends Entity
     *  {
     *      private var mLevel:int;
     *      private var mScore:int;
     *      
     *      public function GameState(level:int=0, score:int=0)
     *      {
     *          mLevel = level;
     *          mScore = score;
     *      }
     *      
     *      public function get level():int { return mLevel; }
     *      public function set level(value:int):void { mLevel = value; }
     *      
     *      public function get score():int { return mScore; }
     *      public function set score(value:int):void { mScore = value; }
     *  }</pre>
     *  
     */
    public class Entity
    {
        private var mId:String;
        private var mCreatedAt:Date;
        private var mUpdatedAt:Date;
        private var mOwnerId:String;
        private var mPublicAccess:String;
        
        private static const sTypeCache:Dictionary = new Dictionary();
        private static const sIndices:Dictionary = new Dictionary();
        
        /** Abstract class constructor. Call this via 'super' from your subclass, passing your
         *  custom type string. */
        public function Entity()
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "com.gamua.flox::Entity")
            {
                throw new Error("Abstract class -- do not instantiate");
            }
            
            mId = createUID();
            mCreatedAt = new Date();
            mUpdatedAt = new Date();
            mOwnerId = Flox.currentPlayer ? Flox.currentPlayer.id : null; 
            mPublicAccess = "";
        }
        
        /** Returns a description of the entity, containing its basic information. */
        public function toString():String
        {
            return formatString(
                '[Entity type="{0}" id="{1}" createdAt="{2}" updatedAt="{3}" ownerId="{4}"]',
                type, mId, DateUtil.toString(mCreatedAt), DateUtil.toString(mUpdatedAt), mOwnerId);
        }
        
        /** Saves the entity on the server; if the entity already exists, the server version will
         *  be updated with the local changes. It is guaranteed that one (and only one) of the 
         *  provided callbacks will be executed; all callback arguments are optional.
         * 
         *  <p>In case of an error, use the method 'HttpStatus.isTransientError(httpStatus)'
         *  to find out if the error is just temporary (e.g. the server was not reachable).</p> 
         *  
         *  @param onComplete: executed when the operation is successful; function signature:
         *                     <pre>onComplete(entity:Entity):void;</pre>
         *  @param onError:    executed when the operation was not successful; function signature:
         *                     <pre>onError(error:String, httpStatus:int):void;</pre>         
         */
        public function save(onComplete:Function, onError:Function):void
        {
            Entity.save(this, onComplete, onError);
        }
        
        /** Saves the entity the next time the player goes online. When the Flox server cannot be
         *  reached at the moment, the request will be added to a queue and will be repeated
         *  later. */
        public function saveQueued():void
        {
            Entity.saveQueued(this);
        }
        
        /** Refreshes the entity with the version that is currently stored on the server.
         *  It is guaranteed that one (and only one) of the provided callbacks will be executed;
         *  all callback arguments are optional.
         * 
         *  <p>The 'fromCache' argument indicates that the entity hasn't changed since you last
         *  received it from the server. In case of an error, use the method  
         *  'HttpStatus.isTransientError(httpStatus)' to find out if it's just temporary (e.g. the 
         *  server was not reachable).</p> 
         *  
         *  @param onComplete: executed when the operation is successful; function signature:
         *                     <pre>onComplete(entity:Entity, fromCache:Boolean):void;</pre>
         *  @param onError:    executed when the operation was not successful; function signature:
         *                     <pre>onError(error:String, httpStatus:int):void;</pre>         
         */
        public function refresh(onComplete:Function, onError:Function):void
        {
            Entity.refresh(this, onComplete, onError);
        }
        
        /** Deletes the entity from the server. It is guaranteed that one (and only one) of the 
         *  provided callbacks will be executed; all callback arguments are optional.
         * 
         *  <p>In case of an error, use the method 'HttpStatus.isTransientError(httpStatus)' 
         *  to find out if the error is just temporary (e.g. the server was not reachable).</p> 
         *  
         *  @param onComplete:  executed when the operation is successful; function signature:
         *                      <pre>onComplete(entity:Entity):void;</pre>
         *  @param onError:     executed when the operation was not successful; function signature:
         *                      <pre>onError(error:String, httpStatus:int):void;</pre>         
         */
        public function destroy(onComplete:Function, onError:Function):void
        {
            var self:Entity = this;
            Entity.destroy(getClass(this), mId, onDestroyComplete, onError);
            
            function onDestroyComplete():void
            {
                execute(onComplete, self);
            }
        }
        
        /** Deletes the entity the next time the player goes online. When the Flox server cannot be
         *  reached at the moment, the request will be added to a queue and will be repeated
         *  later. */
        public function destroyQueued():void
        {
            Entity.destroyQueued(getClass(this), mId);
        }

        // static methods
        
        /** Loads an entity with the given type and ID from the server.
         *  It is guaranteed that one (and only one) of the provided callbacks will be executed;
         *  all callback arguments are optional.
         *  
         *  <p>The 'fromCache' argument indicates if the entity has changed since you last 
         *  received it from the server.</p>
         *  
         *  <p>Note that the 'onError' callback may give you a cached version of the entity. This
         *  is possible if you have received the Entity already in the past. This might allow you
         *  to work with the entity even though the player has lost the connection to the Flox
         *  server.</p>
         * 
         *  <p>If there is no Entity with this type and ID stored on the server, the 'httpStatus'
         *  of the 'onError' callback will be 'HttpStatus.NOT_FOUND'.</p>
         *  
         *  @param entityClass: the class of the entity to load.
         *  @param id:          the id of the entity to load.
         *  @param onComplete:  executed when the operation is successful; function signature:
         *                      <pre>onComplete(entity:Entity, fromCache:Boolean):void;</pre>
         *  @param onError:     executed when the operation was not successful; function signature:
         *                      <pre>onError(error:String, httpStatus:int, cachedEntity:Entity):void;</pre>
         */
        public static function load(entityClass:Class, id:String, 
                                    onComplete:Function, onError:Function):void
        {
            var entity:Entity;
            var type:String = getType(entityClass);
            var path:String = createEntityURL(type, id);
            
            Flox.service.request(HttpMethod.GET, path, null, onRequestComplete, onRequestError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                entity = Entity.fromObject(type, id, body);
                execute(onComplete, entity, httpStatus == HttpStatus.NOT_MODIFIED);
            }
            
            function onRequestError(error:String, httpStatus:int, cachedBody:Object):void
            {
                entity = Entity.fromObject(type, id, cachedBody); 
                execute(onError, error, httpStatus, entity);
            }
        }

        /** Deletes an entity with the given type and ID from the server.
         *  It is guaranteed that one (and only one) of the provided callbacks will be executed;
         *  all callback arguments are optional.
         * 
         *  <p>In case of an error, use the method 'HttpStatus.isTransientError(httpStatus)' to 
         *  find out if the error is just temporary (e.g. the server was not reachable).</p> 
         *  
         *  @param entityClass: the class of the entity that will be destroyed.
         *  @param id:          the ID of the entity that will be destroyed.
         *  @param onComplete:  executed when the operation is successful; function signature:
         *                      <pre>onComplete():void;</pre>
         *  @param onError:     executed when the operation was not successful; function signature:
         *                      <pre>onError(error:String, httpStatus:int):void;</pre>         
         */
        public static function destroy(entityClass:Class, id:String, 
                                       onComplete:Function, onError:Function):void
        {
            var path:String = createEntityURL(getType(entityClass), id);
            Flox.service.request(HttpMethod.DELETE, path, null, onRequestComplete, onError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                execute(onComplete);
            }
        }
        
        /** Deletes an entity the next time the player goes online. When the Flox server cannot be
         *  reached at the moment, the request will be added to a queue and will be repeated
         *  later. */
        public static function destroyQueued(entityClass:Class, id:String):void
        {
            var path:String = createEntityURL(getType(entityClass), id);
            Flox.service.requestQueued(HttpMethod.DELETE, path);
        }
        
        private static function save(entity:Entity, onComplete:Function, onError:Function):void
        {
            var path:String = createEntityURL(entity.type, entity.id);
            Flox.service.request(HttpMethod.PUT, path, entity.toObject(), 
                                 onRequestComplete, onError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                execute(onComplete, entity);
            }
        }
        
        private static function saveQueued(entity:Entity):void
        {
            var path:String = createEntityURL(entity.type, entity.id);
            Flox.service.requestQueued(HttpMethod.PUT, path, entity.toObject());
        }
        
        private static function refresh(entity:Entity, onComplete:Function, onError:Function):void
        {
            var path:String = createEntityURL(entity.type, entity.id);
            Flox.service.request(HttpMethod.GET, path, null, onRequestComplete, onError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                if (httpStatus == HttpStatus.NO_CONTENT)
                    execute(onError, "Entity has been deleted", httpStatus);
                else
                {
                    refreshEntity(entity, body);
                    execute(onComplete, entity, httpStatus == HttpStatus.NOT_MODIFIED);
                }
            }
        }
        
        // queries
        
        private static function getIndices(entityClass:Class):Array
        {
            prepareIndices(entityClass);
            return sIndices[entityClass];
        }
        
        private static function prepareIndices(entityClass:Class):void
        {
            // TODO: update for new Index architecture.
            /*
            var indices:Array = sIndices[entityClass];
            
            if (indices == null)
            {
                indices = [];
                
                for each (var accessor:XML in describeType(entityClass).accessor)
                    if (accessor.metadata.(@name == "Indexed").length())
                        indices.push(accessor.@name.toXMLString());
                
                sIndices[entityClass] = indices;
            }
            */
        }
        
        /** @private
         *  TODO: set 'public' after updating index logic
         * 
         *  Get a list of entities from the server. The 'options' array is used to construct a
         *  query. Here is a sample query with all available query options. All of them are
         *  optional. Note that you can pass "onComplete" and "onError" either in the 
         *  options-object, or as parameters of the function.
         *  
         *  <p><code>Entity.find(GameSession, {
         *      where: { player: "Barak" },
         *      orderBy: "score", // defaults to "score asc", you can also use "score desc"
         *      offset: 20,
         *      limit: 50,
         *      onComplete: function(entities:Array):void { ... },
         *      onError:    function(error:String):void { ... }
         *  }</code></p>
         * 
         *  @param entityClass: the class of entities you want to find.
         *  @param options:     the query options.
         *  @param onComplete:  executed when the operation is successful; function signature:
         *                      <pre>onComplete(entities:Array):void;</pre>
         *  @param onError:     executed when the operation was not successful; function signature:
         *                      <pre>onError(error:String, httpStatus:int):void;</pre>         
         */
        internal static function find(entityClass:Class, options:Object,
                                      onComplete:Function=null, onError:Function=null):void
        {
            if (options == null) options = {};
            else options = cloneObject(options, filterDate);
            
            var type:String = getType(entityClass);
            var path:String = createEntityURL(type);
            
            if (options.onComplete != null)
            {
                onComplete = options.onComplete;
                delete options["onComplete"];
            }
            
            if (options.onError != null)
            {
                onError = options.onError;
                delete options["onError"];
            }
            
            Flox.service.request(HttpMethod.GET, path, { q: JSON.stringify(options) },
                onRequestComplete, onError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                var entities:Array = [];
                
                for each (var result:Object in body as Array)
                {
                    var id:String = result.id;
                    var eTag:String = result.eTag;
                    entities.push(Entity.fromObject(type, id, result.entity));
                    
                    // TODO: add to cache
                }
                
                execute(onComplete, entities);
            }
        }
        
        // helpers

        /** @private */
        internal function toObject():Object
        {
            // create clone as Object & replace Dates with Strings
            var object:Object = cloneObject(this, filterDate);
            
            // TODO: add indices
            // var indices:Array = Entity.getIndices(getClass(this)); 
            // if (indices && indices.length) object.indices = indices; 
            
            return object;
        }
        
        /** @private */
        internal static function fromObject(type:String, id:String, data:Object):Entity
        {
            var entity:Entity;
            
            if (type in sTypeCache)
                entity = new (sTypeCache[type] as Class)();
            else
                throw new Error("Entity type not recognized: " + type);
            
            entity.id = id;
            refreshEntity(entity, data);
            
            return entity;
        }
        
        private static function refreshEntity(entity:Entity, data:Object):void
        {
            if (entity == null || data == null) return;
            
            for each (var accessor:XML in describeType(entity).accessor)
            {
                var access:String = accessor.@access.toString();
                if (access == "readwrite") 
                    updateProperty(entity, data, accessor.@name.toString(), 
                                                 accessor.@type.toString());
            }
        }
        
        private static function updateProperty(entity:Entity, serverData:Object, 
                                               propertyName:String, propertyType:String):void
        {
            if (propertyName in serverData)
            {
                if (propertyType == "Date")
                    entity[propertyName] = DateUtil.parse(serverData[propertyName]);
                else
                    entity[propertyName] = serverData[propertyName];
            }
        }
        
        private static function createEntityURL(type:String, id:String=null):String
        {
            return createURL("entities", type, id);
        }
        
        private static function filterDate(object:Object):Object
        {
            if (object is Date) return DateUtil.toString(object as Date);
            else return null;
        }
        
        // properties
        
        /** The type of the entity, which is per default the name of class. This is what
         *  groups Entities together on the server. */
        public function get type():String { return getType(getClass(this)); }
        
        /** This is the primary identifier of the entity. It must be unique within the objects of
         *  the same entity type. Allowed are alphanumeric characters, '-' and '_'. */
        public function get id():String { return mId; }
        public function set id(value:String):void
        { 
            if (/[^a-zA-Z0-9\-_]/.test(value))
                throw new Error("Invalid id: use only alphanumeric characters, '-', and '_'.");
            
            mId = value; 
        }
        
        /** The player ID of the owner of the entity. (Referencing a Player entitity.) */
        public function get ownerId():String { return mOwnerId; }
        public function set ownerId(value:String):void { mOwnerId = value; }
        
        /** The access rights of all players except the owner.
         *  (The owner always has unlimited access.) */
        public function get publicAccess():String { return mPublicAccess; }
        public function set publicAccess(value:String):void { mPublicAccess = value ? value : ""; }
        
        /** The date when this entity was created. */
        public function get createdAt():Date { return mCreatedAt; }
        public function set createdAt(value:Date):void { mCreatedAt = value; }
        
        /** The date when this entity was last updated on the server. */
        public function get updatedAt():Date { return mUpdatedAt; }
        public function set updatedAt(value:Date):void { mUpdatedAt = value; }
        
        // TODO
        // public function get isSaved():Boolean { return ???; }
        
        // type registration
        
        /** @private
         *  Figures out the type of an entity class as it is used on the server. Per default, this 
         *  is just the class name. You can override this by adding "Type()" metadata to the class
         *  definition. */
        internal static function getType(entityClass:Class):String
        {
            for (var type:String in sTypeCache)
                if (sTypeCache[type] == entityClass) return type;
            
            var typeXml:XML = describeType(entityClass);
            var typeMetaData:XMLList = typeXml.metadata.(@name == "Type");
            var extendsPlayer:XMLList = typeXml.extendsClass.(@type == "com.gamua.flox::Player");
            
            if (typeMetaData.length()) 
                type = typeMetaData.arg.(@key=="").@value.toString();
            else if (extendsPlayer.length())
                type = ".player"; // that simplifies subclassing 'Player'
            else
                type = typeXml.@type.toString().split("::").pop();
            
            sTypeCache[type] = entityClass;
            return type;
        }
        
        /** @private */
        internal static function getClass(instance:Object):Class
        {
            return Object(instance).constructor;
        }
    }
}