--[[ Note: this test file is not at all comprehensive for making sure that field reads/writes
	 translate correctly to terra code.  Right now, all it does it make sure that the codegen
	 produces something that can compile.
]]

import "compiler.liszt"
require "tests.test"

local assert = L.assert
local ioOff = L.require 'domains.ioOff'
local mesh  = ioOff.LoadTrimesh('tests/octa.off')

local V      = mesh.vertices
local T      = mesh.triangles

----------------
-- check args --
----------------
function fail_type1()
	local f = V:NewField('field', 'asdf')
end
function fail_type2()
	local f = V:NewField('field', bool)
end

test.fail_function(fail_type1, "type")
test.fail_function(fail_type2, "type")


-------------------------------
-- Create/initialize fields: --
-------------------------------
T:NewField('field1', L.float)
T:NewField('field2', L.float)
T:NewField('field3', L.float)
T:NewField('field4', L.bool)
T:NewField('field5', L.vector(L.float, 4))

T.field1:LoadConstant(1)
T.field2:LoadConstant(2.5)
T.field3:LoadConstant(6)
T.field4:LoadConstant(false)
T.field5:LoadConstant({ 0, 0, 0, 0 })


-----------------
-- Local vars: --
-----------------
local a = 6
local b = L.Constant(L.vec4f, {1, 3, 4, 5})


---------------------
-- Test functions: --
---------------------
local reduce1 = liszt (t : T)
	t.field1 -= 3 - 1/6 * a
end

local reduce2 = liszt (t : T)
	t.field2 *= 3 * 7 / 3
end

local read1 = liszt (t : T)
	var tmp = t.field3 + 5
	assert(tmp == 11)
end

local write1 = liszt(t : T)
	t.field3 = 0.0f
end

local write2 = liszt (t : T)
	t.field5 = b
end

local reduce3 = liszt (t : T)
	t.field5 += {1.0f,1.0f,1.0f,1.0f}
end

local check2 = liszt (t : T)
	assert(t.field5[0] == 2)
	assert(t.field5[1] == 4)
	assert(t.field5[2] == 5)
	assert(t.field5[3] == 6)
end

local write3 = liszt (t : T)
	t.field4 = true
end

local check3 = liszt (t : T)
	assert(t.field4)
end

local write4 = liszt (t : T)
	t.field4 = false
end

local check4 = liszt(t : T)
	assert(not t.field4)
end


-- execute!
T:map(reduce1)
T:map(reduce2)

T:map(read1)
T:map(write1)
T:map(write2)
T:map(reduce3)
T:map(check2)
T:map(write2)
--
--T:map(write3)
--T:map(check3)
--
--T:map(write4)
--T:map(check4)



--------------------------------------
-- Now the same thing with globals: --
--------------------------------------
local  f = L.Global(L.float, 0.0)
local bv = L.Global(L.bool, true)
local f4 = L.Global(L.vector(L.float, 4), {0, 0, 0, 0})

local function check_write ()
	-- should initialize each field element to {2, 4, 5, 6}
	T:map(write2)
	T:map(reduce3)
--[[
	f4:set({0, 0, 0, 0})
	local sum_positions = liszt (t : T)
		f4 += t.field5
	end
	T:map(sum_positions)

	local f4t = f4:get()
	local fs  = T:Size()
	local avg = { f4t[1]/fs, f4t[2]/fs, f4t[3]/fs, f4t[4]/fs }
	test.fuzzy_aeq(avg, {2, 4, 5, 6})
]]
end
--check_write()
