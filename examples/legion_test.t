-- This file is to test integration of Liszt with Legion. Add code to test
-- features as they are implemented.

print("* This is a Liszt application *")

import "compiler.liszt"

-- Create relations and fields
-- local points = L.NewRelation(4, 'points')
local points = L.NewGridRelation('points', { bounds = {4} })
-- local points = L.NewGridRelation('points', { bounds = {4, 2} })
-- local points = L.NewGridRelation('points', { bounds = {4, 2, 1} })
points:NewField('x', L.int)
points:NewField('y', L.int)
points:NewField('z', L.int)
points:NewField('t', L.int)
-- local edges = L.NewRelation(4, 'edges')
-- edges:NewField('head', points)
-- edges:NewField('tail', points)


-- Create physical region
-- points._logical_region:CreatePhysicalRegion( { fields = { points.x } } )

local liszt kernel CenteredWrite(p : points)
  p.x = 1
end

local liszt kernel CenteredAdd(p : points)
  p.y = 2
  p.z = p.x + p.y
  p.z = p.z + 1
  p.z
end

local liszt kernel ReduceField(p : points)
  p.y += 7
  p.z *= 2
  p.y
  p.z
end

CenteredWrite(points)
CenteredAdd(points)
ReduceField(points)