local function make_weak()
    return setmetatable({}, {__mode = "k"})
end

local AetherDependencies = {
    invisible_instances = make_weak(),
    protected_instances = make_weak(),
    property_spoofs = make_weak(),
    property_blocks = make_weak(),
    class_spoofs = make_weak(),
    remote_fire_hooks = make_weak(),
    remote_fire_blocks = make_weak(),
    remote_invoke_hooks = make_weak(),
    global_env_spoofs = make_weak(),
}

local AetherAPI = {
    
    Version = "v4",
    Changelog = "Улучшение Instance.hide_from_game, терь её тяжелее детектить.",
    
    Memory = {},
    Metatable = {},
    Instance = {},
    Signal = {},
    Network = {},
    Environment = {}
}

local function RegisterFunction(category, name, description, example, func)
    local wrapper = {
        Description = description,
        Example = example
    }
    setmetatable(wrapper, {
        __call = function(self, ...)
            return func(...)
        end
    })
    AetherAPI[category][name] = wrapper
end

RegisterFunction("Memory", "find_function_by_name", 
    "Ищет Luau-функцию в памяти сборщика мусора (GC) по её имени.", 
    [[local func = AetherAPI.Memory.find_function_by_name("cast_ray")]], 
    function(name)
        for _, v in pairs(getgc()) do
            if type(v) == "function" and islclosure(v) and debug.getinfo(v).name == name then
                return v
            end
        end
    end
)

RegisterFunction("Memory", "find_function_by_constant", 
    "Ищет функцию в GC, которая использует указанную константу (строку/число).", 
    [[local func = AetherAPI.Memory.find_function_by_constant("SecretKey123")]], 
    function(constant)
        for _, v in pairs(getgc()) do
            if type(v) == "function" and islclosure(v) then
                if table.find(debug.getconstants(v), constant) then
                    return v
                end
            end
        end
    end
)

RegisterFunction("Memory", "find_function_by_upvalue", 
    "Ищет функцию в GC, у которой есть внешняя переменная (upvalue) с указанным значением.", 
    [[local func = AetherAPI.Memory.find_function_by_upvalue(game.Players.LocalPlayer)]], 
    function(upvalue_val)
        for _, v in pairs(getgc()) do
            if type(v) == "function" and islclosure(v) then
                for _, upv in pairs(debug.getupvalues(v)) do
                    if upv == upvalue_val then return v end
                end
            end
        end
    end
)

RegisterFunction("Memory", "find_table_by_key", 
    "Ищет таблицу в GC, которая содержит указанный строковый ключ.", 
    [[local data = AetherAPI.Memory.find_table_by_key("GemsCount")]], 
    function(key)
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" and rawget(v, key) ~= nil then
                return v
            end
        end
    end
)

RegisterFunction("Memory", "find_table_by_value", 
    "Ищет таблицу в GC, в которой есть указанное значение.", 
    [[local tbl = AetherAPI.Memory.find_table_by_value("Admin")]], 
    function(value)
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" then
                for _, val in pairs(v) do
                    if val == value then return v end
                end
            end
        end
    end
)

RegisterFunction("Memory", "stealth_hook", 
    "Идеальный хук: клонирует оригинал, хукает через C-closure, возвращает чистый клон для вызова.", 
    [[local old; old = AetherAPI.Memory.stealth_hook(target, function() return old() end)]], 
    function(target, hook)
        local cloned = clonefunction(target)
        hookfunction(target, newcclosure(hook))
        return cloned
    end
)

RegisterFunction("Memory", "restore_hook", 
    "Снимает хук с функции, возвращая её в исходное состояние.", 
    [[AetherAPI.Memory.restore_hook(BanFunc)]], 
    function(target)
        if isfunctionhooked(target) then
            restorefunction(target)
        end
    end
)

RegisterFunction("Memory", "is_hooked", 
    "Проверяет, был ли установлен хук на данную функцию.", 
    [[print(AetherAPI.Memory.is_hooked(BanFunc))]], 
    function(target)
        return isfunctionhooked(target)
    end
)

RegisterFunction("Memory", "get_original", 
    "Получает оригинальную функцию (lclosure) из C-closure обертки.", 
    [[local orig = AetherAPI.Memory.get_original(WrappedFunc)]], 
    function(target)
        return get_wrapped_original(target)
    end
)

RegisterFunction("Memory", "make_c_closure", 
    "Маскирует Luau функцию под C функцию для обхода проверок.", 
    [[local c_func = AetherAPI.Memory.make_c_closure(my_func)]], 
    function(target)
        return newcclosure(target)
    end
)

RegisterFunction("Memory", "make_l_closure", 
    "Оборачивает функцию в L closure, стирая её upvalues для античита.", 
    [[local l_func = AetherAPI.Memory.make_l_closure(my_func)]], 
    function(target)
        return newlclosure(target)
    end
)

RegisterFunction("Memory", "disable_function", 
    "Нейтрализует функцию, заставляя её возвращать nil (безопасный хук пустой C-closure).", 
    [[AetherAPI.Memory.disable_function(KickFunc)]], 
    function(target)
        hookfunction(target, newcclosure(function() return end))
    end
)

RegisterFunction("Memory", "get_constant_safe", 
    "Безопасное чтение константы из функции по индексу.", 
    [[local const = AetherAPI.Memory.get_constant_safe(func, 1)]], 
    function(func, index)
        return debug.getconstant(func, index)
    end
)

RegisterFunction("Memory", "set_constant_safe", 
    "Подменяет константу в функции по индексу (например, подмена URL или ключа).", 
    [[AetherAPI.Memory.set_constant_safe(func, 1, "FakeString")]], 
    function(func, index, value)
        debug.setconstant(func, index, value)
    end
)

RegisterFunction("Memory", "set_upvalue_safe", 
    "Подменяет внешнюю локальную переменную в функции по индексу.", 
    [[AetherAPI.Memory.set_upvalue_safe(func, 2, 999)]], 
    function(func, index, value)
        debug.setupvalue(func, index, value)
    end
)

RegisterFunction("Metatable", "get_raw", 
    "Получает метатаблицу объекта в обход защиты __metatable.", 
    [[local mt = AetherAPI.Metatable.get_raw(game)]], 
    function(target)
        return getrawmetatable(target)
    end
)

RegisterFunction("Metatable", "set_raw", 
    "Устанавливает метатаблицу объекту в обход защиты.", 
    [[AetherAPI.Metatable.set_raw(obj, new_mt)]], 
    function(target, mt)
        setrawmetatable(target, mt)
    end
)

RegisterFunction("Metatable", "make_readonly", 
    "Замораживает таблицу, защищая её от изменений античитом.", 
    [[AetherAPI.Metatable.make_readonly(my_table)]], 
    function(target)
        makereadonly(target)
    end
)

RegisterFunction("Metatable", "make_writeable", 
    "Размораживает таблицу, позволяя изменять её содержимое.", 
    [[AetherAPI.Metatable.make_writeable(game_table)]], 
    function(target)
        makewriteable(target)
    end
)

RegisterFunction("Metatable", "is_readonly", 
    "Проверяет, защищена ли таблица от записи.", 
    [[print(AetherAPI.Metatable.is_readonly(game_table))]], 
    function(target)
        return isreadonly(target)
    end
)

RegisterFunction("Instance", "hide_from_game", 
    "Скрывает объект от методов античита (GetChildren, FindFirstChild) и блокирует срабатывание сигналов (ChildAdded, Touched).", 
    [[AetherAPI.Instance.hide_from_game(workspace.MyHitbox)]], 
    function(instance)
        AetherDependencies.invisible_instances[instance] = true
        return instance
    end
)

RegisterFunction("Instance", "unhide_from_game", 
    "Возвращает видимость скрытому объекту.", 
    [[AetherAPI.Instance.unhide_from_game(workspace.MyHitbox)]], 
    function(instance)
        AetherDependencies.invisible_instances[instance] = nil
        return instance
    end
)

RegisterFunction("Instance", "protect_from_deletion", 
    "Блокирует вызовы Destroy, Remove и ClearAllChildren для объекта со стороны игры.", 
    [[AetherAPI.Instance.protect_from_deletion(workspace.MyBase)]], 
    function(instance)
        AetherDependencies.protected_instances[instance] = true
        return instance
    end
)

RegisterFunction("Instance", "unprotect_from_deletion", 
    "Снимает защиту от удаления с объекта.", 
    [[AetherAPI.Instance.unprotect_from_deletion(workspace.MyBase)]], 
    function(instance)
        AetherDependencies.protected_instances[instance] = nil
        return instance
    end
)

RegisterFunction("Instance", "spoof_property", 
    "Подменяет возвращаемое значение свойства объекта при попытке его прочтения игрой.", 
    [[AetherAPI.Instance.spoof_property(Humanoid, "WalkSpeed", 16)]], 
    function(instance, property, fake_value)
        if not AetherDependencies.property_spoofs[instance] then
            AetherDependencies.property_spoofs[instance] = {}
        end
        AetherDependencies.property_spoofs[instance][property] = fake_value
        return instance
    end
)

RegisterFunction("Instance", "unspoof_property", 
    "Удаляет подмену свойства.", 
    [[AetherAPI.Instance.unspoof_property(Humanoid, "WalkSpeed")]], 
    function(instance, property)
        if AetherDependencies.property_spoofs[instance] then
            AetherDependencies.property_spoofs[instance][property] = nil
        end
        return instance
    end
)

RegisterFunction("Instance", "block_property_write", 
    "Запрещает игре изменять указанное свойство объекта.", 
    [[AetherAPI.Instance.block_property_write(Humanoid, "Health")]], 
    function(instance, property)
        if not AetherDependencies.property_blocks[instance] then
            AetherDependencies.property_blocks[instance] = {}
        end
        AetherDependencies.property_blocks[instance][property] = true
        return instance
    end
)

RegisterFunction("Instance", "unblock_property_write", 
    "Разрешает игре изменять свойство объекта.", 
    [[AetherAPI.Instance.unblock_property_write(Humanoid, "Health")]], 
    function(instance, property)
        if AetherDependencies.property_blocks[instance] then
            AetherDependencies.property_blocks[instance][property] = nil
        end
        return instance
    end
)

RegisterFunction("Instance", "spoof_class", 
    "Подменяет возвращаемое значение ClassName и метода IsA.", 
    [[AetherAPI.Instance.spoof_class(Folder, "Part")]], 
    function(instance, fake_class)
        AetherDependencies.class_spoofs[instance] = fake_class
        return instance
    end
)

RegisterFunction("Instance", "get_real_children", 
    "Возвращает настоящий список детей объекта в обход всех хуков игры и эксплоита.", 
    [[local children = AetherAPI.Instance.get_real_children(workspace)]], 
    function(instance)
        local func = clonefunction(game.GetChildren)
        return func(instance)
    end
)

RegisterFunction("Instance", "get_hidden_prop", 
    "Читает скрытое свойство объекта (например, size_xml).", 
    [[local val, hidden = AetherAPI.Instance.get_hidden_prop(Fire, "size_xml")]], 
    function(instance, prop)
        return gethiddenproperty(instance, prop)
    end
)

RegisterFunction("Instance", "set_hidden_prop", 
    "Записывает значение в скрытое свойство объекта.", 
    [[AetherAPI.Instance.set_hidden_prop(Fire, "size_xml", 15)]], 
    function(instance, prop, val)
        return sethiddenproperty(instance, prop, val)
    end
)

RegisterFunction("Instance", "set_scriptable", 
    "Делает недоступное свойство доступным для обычного Lua кода.", 
    [[AetherAPI.Instance.set_scriptable(Part, "Size", true)]], 
    function(instance, prop, state)
        return setscriptable(instance, prop, state)
    end
)

RegisterFunction("Instance", "is_scriptable", 
    "Проверяет, доступно ли свойство для скриптов.", 
    [[print(AetherAPI.Instance.is_scriptable(Part, "Size"))]], 
    function(instance, prop)
        return isscriptable(instance, prop)
    end
)

RegisterFunction("Signal", "disable_all", 
    "Отключает все Lua обработчики для указанного сигнала (ивента).", 
    [[AetherAPI.Signal.disable_all(Humanoid.Died)]], 
    function(signal)
        for _, conn in pairs(getconnections(signal)) do
            conn:Disable()
        end
    end
)

RegisterFunction("Signal", "enable_all", 
    "Включает обратно все отключенные обработчики сигнала.", 
    [[AetherAPI.Signal.enable_all(Humanoid.Died)]], 
    function(signal)
        for _, conn in pairs(getconnections(signal)) do
            conn:Enable()
        end
    end
)

RegisterFunction("Signal", "fire_all", 
    "Искусственно вызывает все обработчики сигнала с вашими аргументами.", 
    [[AetherAPI.Signal.fire_all(Part.Touched, FakePart)]], 
    function(signal, ...)
        firesignal(signal, ...)
    end
)

RegisterFunction("Signal", "disconnect_all", 
    "Навсегда удаляет все обработчики с указанного сигнала.", 
    [[AetherAPI.Signal.disconnect_all(Player.Idled)]], 
    function(signal)
        for _, conn in pairs(getconnections(signal)) do
            conn:Disconnect()
        end
    end
)

RegisterFunction("Signal", "get_foreign", 
    "Возвращает только те соединения, которые были созданы CoreScripts (внутренними скриптами Роблокса).", 
    [[local core_conns = AetherAPI.Signal.get_foreign(Gui.MouseButton1Click)]], 
    function(signal)
        local foreign = {}
        for _, conn in pairs(getconnections(signal)) do
            if conn.ForeignState then
                table.insert(foreign, conn)
            end
        end
        return foreign
    end
)

RegisterFunction("Network", "hook_fire", 
    "Перехватывает FireServer. Обработчик возвращает 'modify' и {args}, либо 'drop'.", 
    [[AetherAPI.Network.hook_fire(Remote, function(args) return "drop" end)]], 
    function(remote, callback)
        AetherDependencies.remote_fire_hooks[remote] = callback
    end
)

RegisterFunction("Network", "unhook_fire", 
    "Снимает перехват с FireServer.", 
    [[AetherAPI.Network.unhook_fire(Remote)]], 
    function(remote)
        AetherDependencies.remote_fire_hooks[remote] = nil
    end
)

RegisterFunction("Network", "block_fire", 
    "Полностью блокирует отправку FireServer для ремута.", 
    [[AetherAPI.Network.block_fire(BanRemote)]], 
    function(remote)
        AetherDependencies.remote_fire_blocks[remote] = true
    end
)

RegisterFunction("Network", "unblock_fire", 
    "Снимает блокировку с FireServer.", 
    [[AetherAPI.Network.unblock_fire(BanRemote)]], 
    function(remote)
        AetherDependencies.remote_fire_blocks[remote] = nil
    end
)

RegisterFunction("Network", "hook_invoke", 
    "Перехватывает InvokeServer. Обработчик возвращает 'modify' и {args}, либо 'drop', либо 'spoof_return' и значение.", 
    [[AetherAPI.Network.hook_invoke(Function, function(args) return "spoof_return", true end)]], 
    function(remote, callback)
        AetherDependencies.remote_invoke_hooks[remote] = callback
    end
)

RegisterFunction("Environment", "spoof_thread_identity", 
    "Изменяет уровень доступа текущего потока (Thread Identity).", 
    [[AetherAPI.Environment.spoof_thread_identity(8)]], 
    function(identity)
        setthreadidentity(identity)
    end
)

RegisterFunction("Environment", "get_thread_identity", 
    "Получает уровень доступа текущего потока.", 
    [[print(AetherAPI.Environment.get_thread_identity())]], 
    function()
        return getthreadidentity()
    end
)

RegisterFunction("Environment", "spoof_global_property", 
    "Глобально подменяет свойство (например, game.PlaceId).", 
    [[AetherAPI.Environment.spoof_global_property(game, "PlaceId", 123456)]], 
    function(target, key, fake_value)
        if not AetherDependencies.global_env_spoofs[target] then
            AetherDependencies.global_env_spoofs[target] = {}
        end
        AetherDependencies.global_env_spoofs[target][key] = fake_value
    end
)

RegisterFunction("Environment", "check_caller", 
    "Проверяет, вызван ли код эксплоитом (true) или игрой (false).", 
    [[print(AetherAPI.Environment.check_caller())]], 
    function()
        return checkcaller()
    end
)

RegisterFunction("Environment", "get_calling_script", 
    "Возвращает скрипт, из которого была вызвана текущая функция.", 
    [[local script = AetherAPI.Environment.get_calling_script()]], 
    function()
        return getcallingscript()
    end
)

RegisterFunction("Environment", "is_executor_closure", 
    "Проверяет, создана ли функция эксплоитом.", 
    [[print(AetherAPI.Environment.is_executor_closure(my_func))]], 
    function(func)
        return isexecutorclosure(func)
    end
)

local old_namecall, old_index, old_newindex

old_index = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() and typeof(self) == "Instance" then
        if AetherDependencies.global_env_spoofs[self] and AetherDependencies.global_env_spoofs[self][key] ~= nil then
            return AetherDependencies.global_env_spoofs[self][key]
        end

        if AetherDependencies.property_spoofs[self] and AetherDependencies.property_spoofs[self][key] ~= nil then
            local spoofed = AetherDependencies.property_spoofs[self][key]
            if type(spoofed) == "function" then
                return spoofed()
            end
            return spoofed
        end
        
        if key == "ClassName" and AetherDependencies.class_spoofs[self] then
            return AetherDependencies.class_spoofs[self]
        end
    end
    return old_index(self, key)
end)

old_newindex = hookmetamethod(game, "__newindex", function(self, key, value)
    if not checkcaller() and typeof(self) == "Instance" then
        if key == "Parent" and value == nil then
            if AetherDependencies.protected_instances[self] then
                return
            end
        end
        
        if AetherDependencies.property_blocks[self] and AetherDependencies.property_blocks[self][key] then
            return
        end
    end
    return old_newindex(self, key, value)
end)

old_namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    if not checkcaller() then
        if typeof(self) == "Instance" then
            if method == "Destroy" or method == "Remove" or method == "ClearAllChildren" then
                if AetherDependencies.protected_instances[self] then
                    return
                end
            end

            if method == "GetChildren" or method == "GetDescendants" then
                local result = old_namecall(self, ...)
                if type(result) == "table" then
                    local filtered = {}
                    for i = 1, #result do
                        if not AetherDependencies.invisible_instances[result[i]] then
                            filtered[#filtered + 1] = result[i]
                        end
                    end
                    return filtered
                end
                return result
            end

            if method == "FindFirstChild" or method == "WaitForChild" or method == "FindFirstChildOfClass" or method == "FindFirstChildWhichIsA" then
                local result = old_namecall(self, ...)
                if result and AetherDependencies.invisible_instances[result] then
                    return nil
                end
                return result
            end
            
            if method == "IsA" then
                local args = {...}
                if AetherDependencies.class_spoofs[self] then
                    if args[1] == AetherDependencies.class_spoofs[self] then return true end
                end
            end

            local className = old_index(self, "ClassName")

            if className == "RemoteEvent" and method == "FireServer" then
                if AetherDependencies.remote_fire_blocks[self] then
                    return
                end
                if AetherDependencies.remote_fire_hooks[self] then
                    local args = {...}
                    local action, new_args = AetherDependencies.remote_fire_hooks[self](args)
                    if action == "drop" then
                        return
                    elseif action == "modify" then
                        return old_namecall(self, unpack(new_args))
                    end
                end
            end

            if className == "RemoteFunction" and method == "InvokeServer" then
                if AetherDependencies.remote_fire_blocks[self] then
                    return nil
                end
                if AetherDependencies.remote_invoke_hooks[self] then
                    local args = {...}
                    local action, new_args = AetherDependencies.remote_invoke_hooks[self](args)
                    if action == "drop" then
                        return nil
                    elseif action == "modify" then
                        return old_namecall(self, unpack(new_args))
                    elseif action == "spoof_return" then
                        return new_args
                    end
                end
            end
            
        elseif typeof(self) == "RBXScriptSignal" then
            if method == "Connect" or method == "ConnectParallel" or method == "Once" then
                local args = {...}
                local original_func = args[1]
                if type(original_func) == "function" then
                    args[1] = newcclosure(function(...)
                        local cargs = {...}
                        for i = 1, #cargs do
                            if typeof(cargs[i]) == "Instance" and AetherDependencies.invisible_instances[cargs[i]] then
                                return
                            end
                        end
                        return original_func(...)
                    end)
                    return old_namecall(self, unpack(args))
                end
            elseif method == "Wait" then
                while true do
                    local wargs = {old_namecall(self, ...)}
                    local hidden = false
                    for i = 1, #wargs do
                        if typeof(wargs[i]) == "Instance" and AetherDependencies.invisible_instances[wargs[i]] then
                            hidden = true
                            break
                        end
                    end
                    if not hidden then
                        return unpack(wargs)
                    end
                end
            end
        end
    end

    return old_namecall(self, ...)
end)

return AetherAPI
