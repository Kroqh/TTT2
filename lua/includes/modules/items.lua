---
-- This is the <code>items</code> module
-- @author Alf21
-- @author saibotk
module("items", package.seeall)

local baseclass = baseclass
local list = list
local pairs = pairs

if SERVER then
	AddCSLuaFile()
end

local ItemList = ItemList or {}

---
-- Copies any missing data from base table to the target table
-- @tab t target table
-- @tab base base (fallback) table
-- @treturn table t target table
local function TableInherit(t, base)
	for k, v in pairs(base) do
		if t[k] == nil then
			t[k] = v
		elseif k ~= "BaseClass" and istable(t[k]) then
			TableInherit(t[k], v)
		end
	end

	t.BaseClass = base

	return t
end

---
-- Checks if name is based on base
-- @tab name table to check
-- @tab base base (fallback) table
-- @treturn boolean returns whether name is based on base
function IsBasedOn(name, base)
	local t = GetStored(name)

	if not t then
		return false
	end

	if t.Base == name then
		return false
	end

	if t.Base == base then
		return true
	end

	return IsBasedOn(t.Base, base)
end

---
-- Used to register your item with the engine.<br />
-- <b>This is done automatically for all the files in the <code>lua/terrortown/entities/items</code> folder</b>
-- @tab t item table
-- @str name item name
function Register(t, name)
	name = string.lower(name)

	local old = ItemList[name]

	t.ClassName = name
	t.id = name

	ItemList[name] = t

	list.Set("Item", name, {
			ClassName = name,
			id = name,
			PrintName = t.PrintName or t.ClassName,
			Category = t.Category or "Other",
			Spawnable = t.Spawnable,
			AdminOnly = t.AdminOnly,
			ScriptedEntityType = t.ScriptedEntityType
	})

	--
	-- If we're reloading this entity class
	-- then refresh all the existing entities.
	--
	if old ~= nil then

		--
		-- For each entity using this class
		--
		for _, entity in ipairs(ents.FindByClass(name)) do

			--
			-- Replace the contents with this entity table
			--
			table.Merge(entity, t)

			--
			-- Call OnReloaded hook (if it has one)
			--
			if isfunction(entity.OnReloaded) then
				entity:OnReloaded()
			end
		end

		-- Update item table of entities that are based on this item
		for _, e in ipairs(ents.GetAll()) do
			if IsBasedOn(e:GetClass(), name) then
				table.Merge(e, Get(e:GetClass()))

				if isfunction(e.OnReloaded) then
					e:OnReloaded()
				end
			end
		end
	end
end


---
-- All scripts have been loaded...
-- @local
function OnLoaded()

	--
	-- Once all the scripts are loaded we can set up the baseclass
	-- - we have to wait until they're all setup because load order
	-- could cause some entities to load before their bases!
	--
	for k in pairs(ItemList) do
		local newTable = Get(k)
		ItemList[k] = newTable

		baseclass.Set(k, newTable)
	end
end

---
-- Get an item by name (a copy)
-- @str name item name
-- @tparam[opt] ?table retTbl this table will be modified and returned. If nil, a new table will be created.
-- @treturn table returns the modified retTbl or the new item table
function Get(name, retTbl)
	local Stored = GetStored(name)
	if not Stored then return end

	-- Create/copy a new table
	local retval = retTbl or {}

	for k, v in pairs(Stored) do
		if istable(v) then
			retval[k] = table.Copy(v)
		else
			retval[k] = v
		end
	end

	retval.Base = retval.Base or "item_base"

	-- If we're not derived from ourselves (a base item)
	-- then derive from our 'Base' item.
	if retval.Base ~= name then
		local base = Get(retval.Base)

		if not base then
			Msg("ERROR: Trying to derive item " .. tostring(name) .. " from non existant item " .. tostring(retval.Base) .. "!\n")
		else
			retval = TableInherit(retval, base)
		end
	end

	return retval
end

---
-- Gets the real item table (not a copy)
-- @str name item name
-- @treturn table returns the real item table
function GetStored(name)
	return ItemList[name]
end


---
-- Get a list of all the registered items
-- @treturn table all registered items
function GetList()
	local result = {}

	for _, v in pairs(ItemList) do
		result[#result + 1] = v
	end

	return result
end

---
-- Checks whether the input is an item
-- @stn val item name / table / id
-- @treturn boolean returns true if the inserted table is an item
function IsItem(val)
	if not val then
		return false
	end

	local tmp = val

	if tonumber(val) then
		for _, item in pairs(ItemList) do
			if item.oldId and item.oldId == val then
				return true
			end
		end
	elseif not isstring(val) and (IsValid(val) or istable(val)) then
		tmp = WEPS.GetClass(val)
	end

	return items.GetStored(tmp) ~= nil
end

---
-- Checks whether the input table has a specific item.<br />
-- This is calling <a href="https://wiki.garrysmod.com/page/table/HasValue">table.HasValue</a> internally,
-- but you don't have to tackle with the input value (<code>val</code>) type
-- @tab tbl target table
-- @stn val item name / table / id
-- @treturn boolean whether the input table has a specific item
function TableHasItem(tbl, val)
	if not tbl or not val then
		return false
	end

	local tmp = val

	if not isstring(val) then
		if tonumber(val) then -- still support the old item system
			for _, item in pairs(ItemList) do
				if item.oldId and item.oldId == val then
					tmp = item.id

					break
				end
			end
		elseif IsValid(val) or istable(val) then
			tmp = WEPS.GetClass(val)
		end
	end

	return table.HasValue(tbl, tmp)
end

---
-- Get all items for this role
-- @int subrole subrole id
-- @treturn table role items table
function GetRoleItems(subrole)
	local itms = GetList()
	local tbl = {}

	for _, item in ipairs(itms) do
		if item and item.CanBuy and table.HasValue(item.CanBuy, subrole) then
			tbl[#tbl + 1] = item
		end
	end

	return tbl
end

---
-- Get a role item if it's available for this role
-- @int subrole subrole id
-- @sn id item id / name
function GetRoleItem(subrole, id)
	if tonumber(id) then
		for _, item in pairs(ItemList) do
			if item.oldId and item.oldId == id then
				id = item.id

				break
			end
		end

		if tonumber(id) then return end
	end

	local item = GetStored(id)

	if item and item.CanBuy and table.HasValue(item.CanBuy, subrole) then
		return item
	end
end
