module StitchingTimeAndSpace

using Images
using Colors
using HDF5
using Printf
using Formatting

function rgb_asUInt8(color::RGBA{Normed{UInt8,8}})
    return reinterpret.([color.r, color.g, color.b])
end

function rawUInt8_to_RGBA(r::UInt8, g::UInt8, b::UInt8)
    RGBA(reinterpret(Normed{UInt8, 8}, r), 
         reinterpret(Normed{UInt8, 8}, g), 
         reinterpret(Normed{UInt8, 8}, b))
end

function createHDF5Container(hdf5_container_filename::String, 
        num_cameras::Integer,
        num_timesnapshots::Integer, 
        single_image_heightwidth::Tuple,
        images_format_format::String)
    
    image_height = single_image_heightwidth[1]
    image_width = single_image_heightwidth[2]


    # do-block will close fid automatically
    h5open(hdf5_container_filename, "w") do fid
        # mmap used for both writing and reading to HDF5
        # mmap requires no chunking nor compression

        # Each camera gets its own dataset
        # Prelimary testing: using one big dataset with all cameras resulted in slow writes
        # e.g.
        # dset = create_dataset(fid, "images/Cam$f", 
        #   datatype(UInt8), 
        #   dataspace(500, 100, 500, 500, 3), 
        #   alloc_time = HDF5.H5D_ALLOC_TIME_EARLY)

        println("Creating entire HDF5 container `$hdf5_container_filename`...")
        @time for f in 1:num_cameras
            dset = create_dataset(fid, "images/Cam$f", 
                datatype(UInt8), #TODO: May depend on images
                dataspace(num_timesnapshots, image_height, image_width, 3), 
                alloc_time = HDF5.H5D_ALLOC_TIME_EARLY) #Allows mmap access immediately
        end
    
        # Preallocate empty image
        img = Array{RGBA{Normed{UInt8,8}}}(undef, (image_height, image_width)) 
        rgb_asUInt8(img[1,1]); #force compile
        
        println("Saving each image to HDF5 container...")
        @time for f in 1:num_cameras
            @assert HDF5.ismmappable(fid["images"]["Cam$f"])
            dset = HDF5.readmmap(fid["images"]["Cam$f"]) #Important to use mmap for speed-up
            for g in 1:num_timesnapshots
                print("(f = $f / $num_cameras), (g = $g / $num_timesnapshots)")
                global img = load(format(images_format_format, f, g))
        
                @time for i in 1:image_height, j in 1:image_width
                    dset[g, i, j, :] = rgb_asUInt8(img[i, j])
                end
            end
        end
    end

    return true
end

end