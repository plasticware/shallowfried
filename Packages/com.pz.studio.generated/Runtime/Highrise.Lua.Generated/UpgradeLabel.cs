/*

    Copyright (c) 2025 Pocketz World. All rights reserved.

    This is a generated file, do not edit!

    Generated by com.pz.studio
*/

#if UNITY_EDITOR

using System;
using System.Linq;
using UnityEngine;
using Highrise.Client;
using Highrise.Studio;
using Highrise.Lua;

namespace Highrise.Lua.Generated
{
    [AddComponentMenu("Lua/UpgradeLabel")]
    [LuaRegisterType(0x495875d3997b132f, typeof(LuaBehaviour))]
    public class UpgradeLabel : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "ecf6f7b09aabe9c48b1afc2169c3207e";
        public override string ScriptGUID => s_scriptGUID;


        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), null),
                CreateSerializedProperty(_script.GetPropertyAt(1), null),
                CreateSerializedProperty(_script.GetPropertyAt(2), null),
                CreateSerializedProperty(_script.GetPropertyAt(3), null),
            };
        }
    }
}

#endif
