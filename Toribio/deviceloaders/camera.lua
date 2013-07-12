
local M = {}

M.init = function(conf)
	cv=require('luacv')
	local toribio = require 'toribio'
	local utils = require 'tasks/utils'
	local sched = require 'sched'
	capture = cv.CreateCameraCapture(conf.cam_id)
   -- print ('coso')
 	 if not capture then
 	 	print('no captura')
 	 end
 	 
	local camevent = {} --events
	-- local frame = cv.QueryFrame(capture);
    cv.SetCaptureProperty(capture, cv.CV_CAP_PROP_FRAME_WIDTH, conf.FRAME_WIDTH);
    cv.SetCaptureProperty(capture, cv.CV_CAP_PROP_FRAME_HEIGHT, conf.FRAME_HEIGHT);	
	--local image;
	--local image =cv.CreateImage( cv.Size(width,height), cv.IPL_DEPTH_8U, 3 )
	--cv.Zero( image );
	local device={}
	
	device.name = 'camera'
	device.module='camera'
	
	device.events={
		camevent=camevent,
	}


function white_mask( imagen, H_MIN, H_MAX, S_MIN, S_MAX, V_MIN, V_MAX )
		local element = cv.CreateStructuringElementEx(3, 3, 1, 1, cv.CV_SHAPE_RECT)   
		local element2 = cv.CreateStructuringElementEx(3, 3, 1, 1, cv.CV_SHAPE_RECT)
		local DELAY = 5
		local min_area = 2000 --no se usa
		local result_image = nil

		if imagen then
			local imageHSV = cv.CreateImage(cv.GetSize(imagen), cv.IPL_DEPTH_8U, 3)
			cv.CvtColor(imagen, imageHSV, cv.CV_BGR2HSV)
			if imageHSV then
				local imageThres = cv.CreateImage(cv.GetSize(imageHSV), cv.IPL_DEPTH_8U, 1)
				cv.InRangeS(imageHSV, cv.Scalar(H_MIN,S_MIN, V_MIN,0), cv.Scalar(H_MAX,S_MAX,V_MAX,0), imageThres)

				local imgtmp = utils.morphOps(imageThres, element, element2)
				local mayor_contorno = utils.contorno_mas_grande(imgtmp, min_area)
				sched.yield()
				if mayor_contorno then
					result_image = utils.draw_cont(imagen, mayor_contorno)
				else
					result_image = imagen
				end

				cv.ReleaseImage(imageHSV)
				cv.ReleaseImage(imageThres)
				cv.ReleaseImage(imgtmp)
			end

		end
		
		return result_image		
	end


	
	   -- print ('pre sched')
	device.task = sched.run(function()
		while true do

			-- if frame then
			-- 	cv.ReleaseImage(frame)
			-- end

			frame = cv.QueryFrame(capture);
			if not (frame) then
			    print('Sin captura')
			    break
			end
			 cv.ReleaseImage(frame)
			frame = cv.QueryFrame(capture);
			if not (frame) then
			    print('Sin captura')
			    break
			end 
			cv.ReleaseImage(frame)
			frame = cv.QueryFrame(capture);
			if not (frame) then
			    print('Sin captura')
			    break
			end
			 cv.ReleaseImage(frame)
			frame = cv.QueryFrame(capture);
			if not (frame) then
			    print('Sin captura')
			    break
			end 
			cv.ReleaseImage(frame)
			 frame = cv.QueryFrame(capture);
			if not (frame) then
			    print('Sin captura')
			    break
			end 
			--  cv.ReleaseImage(frame)
			--  frame = cv.QueryFrame(capture);
			-- if not (frame) then
			--     print('Sin captura')
			--     break
			-- end 
			-- cv.ReleaseImage(frame)
			-- frame = cv.QueryFrame(capture);
			-- if not (frame) then
			--     print('Sin captura')
			--     break
			-- end 
			-- cv.ReleaseImage(frame)
			-- frame = cv.QueryFrame(capture);
			-- if not (frame) then
			--     print('Sin captura')
			--     break
			-- end 
			-- cv.ReleaseImage(frame)

			-- frame = cv.QueryFrame(capture);
			-- if not (frame) then
			--     print('Sin captura')
			--     break
			-- end
			
			frame = white_mask(frame, 0, 175, 0 ,48, 45, 255)
	 
			sched.signal(camevent)
			-- sched.sleep(0.1)
			sched.yield()
		    cv.ReleaseImage(frame)      
		end
	end)
 
	
	device.get_image=function()
	    local image =cv.CreateImage(cv.GetSize(frame), cv.IPL_DEPTH_8U, 3 )
	    cv.Copy(frame,image)
		return image
		end
	

	
    toribio.add_device( device )
 
end
return M
