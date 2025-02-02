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
    [AddComponentMenu("Lua/PlayerManager")]
    [LuaRegisterType(0xfe9baceb5f86083f, typeof(LuaBehaviour))]
    public class PlayerManager : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "b93c2cc49bf171445a7b2dc17cc4ef4b";
        public override string ScriptGUID => s_scriptGUID;

        [SerializeField] public Highrise.AudioShader m_failSound = default;
        [SerializeField] public Highrise.AudioShader m_clickSound = default;
        [SerializeField] public Highrise.AudioShader m_spendSound = default;
        [SerializeField] public Highrise.AudioShader m_whooshSound = default;
        [SerializeField] public Highrise.AudioShader m_bangSound = default;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), m_failSound),
                CreateSerializedProperty(_script.GetPropertyAt(1), m_clickSound),
                CreateSerializedProperty(_script.GetPropertyAt(2), m_spendSound),
                CreateSerializedProperty(_script.GetPropertyAt(3), m_whooshSound),
                CreateSerializedProperty(_script.GetPropertyAt(4), m_bangSound),
            };
        }
    }
}

#endif
