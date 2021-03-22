cd(@__DIR__)

include("../../src/StitchingTimeAndSpace.jl")
using .StitchingTimeAndSpace

StitchingTimeAndSpace.createHDF5Container("Output/WallOfBlocks750Images", 
    500, 
    100,
    (750, 750), 
    "InputRaw/WallOfBlocks750/SecondaryCamera{1:03d}/{2:03d}.png")