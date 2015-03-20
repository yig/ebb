import "compiler.liszt"


-- In this tutorial, we're going to write a spring-mass simulation
-- instead of a heat-diffusion simulation.  The code will be pretty
-- similar structurally, so it should be straightforward to understand.

-- Now, instead of using OFF files and Trimesh,
-- we'll use VEG files and Tetmesh; otherwise, it'll be very similar
local ioVeg = L.require 'domains.ioVeg'
local PN    = L.require 'lib.pathname'
local cmath = terralib.includecstring '#include <math.h>'

local tet_mesh_filename = PN.scriptdir() .. 'dragon.veg'
local dragon = ioVeg.LoadTetmesh(tet_mesh_filename)


------------------------------------------------------------------------------

-- Declare constants
-- Note: L.vec3d == L.vector(L.double, 3)
--    the d is for double not dimension
local timestep      = L.Constant(L.double, 0.0002)
local spring_K      = L.Constant(L.double, 2000.0)
local damping       = L.Constant(L.double, 0.5)
local gravity       = L.Constant(L.vec3d, {0,-0.98,0})


-- Every Tetmesh mesh comes equipped with a position field
--      'pos' of L.vec3d by default
-- We'll add velocity, acceleration, and mass fields
dragon.vertices:NewField('vel', L.vec3d)        :Load({0,0,0})
dragon.vertices:NewField('acc', L.vec3d)        :Load({0,0,0})
dragon.vertices:NewField('mass', L.double)      :Load(1)
dragon.vertices:NewField('inv_mass', L.double)  :Load(1)

-- And let's record the resting length of all the edges / springs
dragon.edges:NewField('rest_len', L.double)     :Load(0)

-- We'll initialize the mass and resting length using parallel functions
local liszt init_rest_len ( e : dragon.edges )
  var diff = e.head.pos - e.tail.pos
  e.rest_len = L.length(diff)
end
-- (hacky choice of mass to produce a diagonally dominant system)
local liszt init_mass ( v : dragon.vertices )
  v.mass = 1.0e-3
  for e in v.edges do
    v.mass += e.rest_len
  end
  v.inv_mass = 1.0 / v.mass
end

dragon.edges:map(init_rest_len)
dragon.vertices:map(init_mass)

-- Also, let's translate the dragon up above the y=0 plane
-- so we can drop it onto the ground
local liszt lift_dragon ( v : dragon.vertices )
  v.pos += {0,2.3,0}
end
dragon.vertices:map(lift_dragon)

------------------------------------------------------------------------------

-- Now let's define functions to perform the basic updates in our simualtion
-- We're going to use a simple forward Euler integration scheme here.

local liszt compute_acceleration ( v : dragon.vertices )
  -- Force due to gravitational acceleration
  var force = gravity * v.mass

  -- Penalty Force for ground (another spring force for simplicity)
  if v.pos[1] < 0.0 then
    force += { 0, - spring_K * v.pos[1], 0 }
  end

  -- Force due to springs
  for e in v.edges do
    var evec  = e.head.pos - v.pos
    var norm  = evec / L.length(evec)
    var rest  = e.rest_len * norm
    force -= spring_K * (rest - evec)
  end

  v.acc = force * v.inv_mass
end

local liszt update_vel_pos ( v : dragon.vertices )
  v.pos += timestep * v.vel + 0.5 * timestep * timestep * v.acc
  v.vel = (1.0 - damping * timestep) * v.vel
          + (timestep * v.acc)
end

------------------------------------------------------------------------------

-- Again, we won't discuss VDB here, but I'm going to include
-- a little bit of code to visualize the result

-- START EXTRA VDB CODE
local sqrt3 = math.sqrt(3)
local vdb   = L.require('lib.vdb')
local liszt compute_normal ( t : dragon.triangles )
  var p0  = t.v[0].pos
  var p1  = t.v[1].pos
  var p2  = t.v[2].pos
  var n   = L.cross(p1-p0, p2-p0)
  var len = L.length(n)
  if len < 1.0e-6 then len = 1.0e6 else len = 1.0/len end -- invert len
  return n * len
end
local liszt debug_tri_draw ( t : dragon.triangles )
  -- Spoof a really simple directional light with a cos diffuse term
  var d = L.dot({1/sqrt3, -1/sqrt3, 1/sqrt3}, compute_normal(t))
  if d > 1.0 then d = 1.0 end
  if d < -1.0 then d = -1.0 end
  var val = d * 0.5 + 0.5
  var col : L.vec3d = {val,val,val}
  vdb.color(col)
  vdb.triangle(t.v[0].pos, t.v[1].pos, t.v[2].pos)
end
-- END EXTRA VDB CODE

------------------------------------------------------------------------------

-- Now, let's try running this simulation for a while

for i=1,40000 do
  dragon.vertices:map(compute_acceleration)
  dragon.vertices:map(update_vel_pos)

  -- EXTRA: VDB (For visualization)
  if i%100 == 0 then
    vdb.vbegin()
      vdb.frame() -- this call clears the canvas for a new frame
      dragon.triangles:map(debug_tri_draw)
    vdb.vend()
  end
  if i%1000 == 0 then print('iter', i) end
  -- END EXTRA
end








