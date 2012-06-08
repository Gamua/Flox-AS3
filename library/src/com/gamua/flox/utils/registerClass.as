package com.gamua.flox.utils
{
    import flash.net.registerClassAlias;
    import flash.utils.getQualifiedClassName;

    /** Registers the default alias for a class. */
    public function registerClass(type:Class):void
    {
        registerClassAlias(getQualifiedClassName(type), type);
    }
}