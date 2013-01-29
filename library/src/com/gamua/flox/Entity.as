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
    import flash.utils.getDefinitionByName;
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
     *  [Type("gameState")] // optional! Defaults to class name
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
        private var mID:String;
        private var mCreatedAt:Date;
        private var mUpdatedAt:Date;
        private var mOwnerID:String;
        private var mPermissions:Object;
        
        private static var sTypeCache:Dictionary = new Dictionary();
        
        /** Abstract class constructor. Call this via 'super' from your subclass, passing your
         *  custom type string. */
        public function Entity()
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "com.gamua.flox::Entity")
            {
                throw new Error("Abstract class -- do not instantiate");
            }
            
            mID = createUID();
            mCreatedAt = new Date();
            mUpdatedAt = new Date();
            mOwnerID = Flox.localPlayer ? Flox.localPlayer.id : null; 
            mPermissions = {};
        }
        
        /** Returns a description of the entity, containing its basic information. */
        public function toString():String
        {
            return formatString(
                '[Entity type="{0}" id="{1}" createdAt="{2}" updatedAt="{3}" ownerId="{4}"]',
                type, mID, DateUtil.toString(mCreatedAt), DateUtil.toString(mUpdatedAt), mOwnerID);
        }
        
        /** Save the entity on the server; if the entity already exists, the server version will
         *  be updated with the local changes. It is guaranteed that one (and only one) of the 
         *  provided callbacks will be executed; all callback arguments are optional.
         * 
         *  <p>The 'transient' argument tells you if the error might go away if you try again 
         *  (e.g. the server was not reachable).</p> 
         *  
         *  @param onComplete: executed when the operation is successful; function signature:
         *                     <pre>onComplete(entity:Entity):void;</pre>
         *  @param onError:    executed when the operation was not successful; function signature:
         *                     <pre>onError(error:String, transient:Boolean):void;</pre>         
         */
        public function save(onComplete:Function, onError:Function):void
        {
            var self:Entity = this;
            var path:String = createURL(type, mID);
            
            Flox.service.request(HttpMethod.PUT, path, this.toObject(), 
                onRequestComplete, onRequestError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                execute(onComplete, self);
            }
            
            function onRequestError(error:String, httpStatus:int):void
            {
                execute(onError, error, HttpStatus.isTransientError(httpStatus));
            }
        }
        
        /** Refresh the entity with the version that is currently stored on the server.
         *  It is guaranteed that one (and only one) of the provided callbacks will be executed;
         *  all callback arguments are optional.
         * 
         *  <p>The 'fromCache' argument indicates that the entity hasn't changed since you last
         *  received it from the server. The 'transient' argument tells you if the error might 
         *  go away if you try again (e.g. the server was not reachable).</p> 
         *  
         *  @param onComplete: executed when the operation is successful; function signature:
         *                     <pre>onComplete(entity:Entity, fromCache:Boolean):void;</pre>
         *  @param onError:    executed when the operation was not successful; function signature:
         *                     <pre>onError(error:String, transient:Boolean):void;</pre>         
         */
        public function refresh(onComplete:Function, onError:Function):void
        {
            var path:String = createURL(type, mID);
            var self:Entity = this;
            
            Flox.service.request(HttpMethod.GET, path, null, onRequestComplete, onRequestError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                refreshEntity(self, body);
                execute(onComplete, self, httpStatus == HttpStatus.NOT_MODIFIED);
            }
            
            function onRequestError(error:String, httpStatus:int):void
            {
                execute(onError, error, HttpStatus.isTransientError(httpStatus));
            }
        }
        
        /** Deletes the entity from the server.
         *  It is guaranteed that one (and only one) of the provided callbacks will be executed;
         *  all callback arguments are optional.
         * 
         *  <p>The 'transient' argument tells you if the error might go away if you try again 
         *  (e.g. the server was not reachable).</p> 
         *  
         *  @param onComplete: executed when the operation is successful; function signature:
         *                     <pre>onComplete(entity:Entity):void;</pre>
         *  @param onError:    executed when the operation was not successful; function signature:
         *                     <pre>onError(error:String, transient:Boolean):void;</pre>         
         */
        public function destroy(onComplete:Function, onError:Function):void
        {
            var self:Entity = this;
            Entity.destroy(getClass(this), mID, onDestroyComplete, onDestroyError);
            
            function onDestroyComplete():void
            {
                execute(onComplete, self);
            }
            
            function onDestroyError(error:String, httpStatus:int):void
            {
                execute(onError, error, HttpStatus.isTransientError(httpStatus));
            }
        }
        
        // static methods
        
        // onComplete(entity:Entity, fromCache:Boolean)
        // onError(error:String, cachedEntity:Entity)
        
        /** Loads an entity with the given type and ID from the server.
         *  It is guaranteed that one (and only one) of the provided callbacks will be executed;
         *  all callback arguments are optional.
         *  
         *  <p>The 'fromCache' argument indicates that the entity hasn't changed since you last
         *  received it from the server.</p>
         *  
         *  <p>Note that the 'onError' callback may give you a cached version of the entity. This
         *  is possible if you have received the Entity already in the past. This might allow you
         *  to work with the entity even though the player has lost the connection to the Flox
         *  server.</p>
         *  
         *  @param onComplete: executed when the operation is successful; function signature:
         *                     <pre>onComplete(entity:Entity, fromCache:Boolean):void;</pre>
         *  @param onError:    executed when the operation was not successful; function signature:
         *                     <pre>onError(error:String, cachedEntity:Entity):void;</pre>
         */
        public static function load(entityClass:Class, id:String, 
                                    onComplete:Function, onError:Function):void
        {
            var entity:Entity;
            var type:String = getType(entityClass);
            var path:String = createURL(type, id);
            
            Flox.service.request(HttpMethod.GET, path, null, onRequestComplete, onRequestError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                entity = Entity.fromObject(type, id, body);
                execute(onComplete, entity, httpStatus == HttpStatus.NOT_MODIFIED);
            }
            
            function onRequestError(error:String, httpStatus:int, cachedBody:Object):void
            {
                entity = cachedBody ? Entity.fromObject(type, id, cachedBody) : null; 
                execute(onError, error, entity);
            }
        }
        
        /** Deletes the entity with the given type and ID from the server.
         *  It is guaranteed that one (and only one) of the provided callbacks will be executed;
         *  all callback arguments are optional.
         * 
         *  <p>The 'transient' argument tells you if the error might go away if you try again 
         *  (e.g. the server was not reachable).</p> 
         *  
         *  @param onComplete: executed when the operation is successful; function signature:
         *                     <pre>onComplete():void;</pre>
         *  @param onError:    executed when the operation was not successful; function signature:
         *                     <pre>onError(error:String, transient:Boolean):void;</pre>         
         */
        public static function destroy(entityClass:Class, id:String, 
                                       onComplete:Function, onError:Function):void
        {
            var path:String = createURL(getType(entityClass), id);
            Flox.service.request(HttpMethod.DELETE, path, null, onRequestComplete, onRequestError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                execute(onComplete);
            }
            
            function onRequestError(error:String, httpStatus:int):void
            {
                execute(onError, error, HttpStatus.isTransientError(httpStatus));
            }
        }
        
        // queued requests
        
        /** Save the object the next time the player goes online. When the Flox server cannot be
         *  reached at the moment, the request will be added to a queue and will be repeated
         *  later. */
        public function saveQueued():void
        {
            Flox.service.requestQueued(HttpMethod.PUT, createURL(type, mID), toObject());
        }
        
        /** Delete the object the next time the player goes online. When the Flox server cannot be
         *  reached at the moment, the request will be added to a queue and will be repeated
         *  later. */
        public function destroyQueued():void
        {
            Flox.service.requestQueued(HttpMethod.DELETE, createURL(type, mID));
        }
        
        // helpers

        /** @private */
        internal function toObject():Object
        {
            var object:Object = cloneObject(this);

            object["ownerId"] = mOwnerID;
            object["createdAt"] = DateUtil.toString(mCreatedAt);
            object["updatedAt"] = DateUtil.toString(mUpdatedAt);

            if ("authID" in object)
                object["authId"] = object["authID"]; // note case 'Id' vs. 'ID'! 

            delete object["ownerID"];
            delete object["authID"];
            
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
            for each (var accessor:XML in describeType(entity).accessor)
            {
                var access:String = accessor.@access.toString();
                if (access == "readwrite") 
                    updateProperty(entity, data, accessor.@name.toString());
            }
        }
        
        private static function updateProperty(entity:Entity, serverData:Object, 
                                               propertyName:String):void
        {
            var clientPN:String = propertyName;
            var serverPN:String = propertyName;
            
            if      (propertyName == "ownerID") { clientPN = "ownerID"; serverPN = "ownerId"; }
            else if (propertyName == "authID")  { clientPN = "authID";  serverPN = "authId";  }
            
            if (serverPN in serverData)
            {
                if (propertyName == "createdAt" || propertyName == "updatedAt")
                    entity[clientPN] = DateUtil.parse(serverData[serverPN]);
                else
                    entity[clientPN] = serverData[serverPN];
            }
        }
        
        // properties
        
        /** The type of the entity, which is per default the name of class. This is what
         *  groups Entities together on the server. */
        public function get type():String { return getType(getClass(this)); }
        
        /** This is the primary identifier of the entity. It must be unique within the objects of
         *  the same entity type. */
        public function get id():String { return mID; }
        public function set id(value:String):void { mID = value; }
        
        /** The player ID of the owner of the entity. (Referencing a Player entitity.) */
        public function get ownerID():String { return mOwnerID; }
        public function set ownerID(value:String):void { mOwnerID = value; }
        
        /** A set of permissions for the entity. TODO add more info here. */
        public function get permissions():Object { return mPermissions; }
        public function set permissions(value:Object):void { mPermissions = value ? value : {}; }
        
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