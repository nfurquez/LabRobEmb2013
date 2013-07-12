#!/usr/bin/env lua
local cv=require('luacv')

local element = cv.CreateStructuringElementEx(3, 3, 1, 1, cv.CV_SHAPE_RECT)   
local element2 = cv.CreateStructuringElementEx(7, 7, 1, 1, cv.CV_SHAPE_RECT)
local storage=cv.CreateMemStorage()
local storage_hull=cv.CreateMemStorage()
local DELAY = 5

local function morphOps(imagethresh)
    erode = cv.CreateImage(cv.GetSize(imagethresh), cv.IPL_DEPTH_8U, 1)
    cv.Erode(imagethresh,erode, element, 1) 
    cv.ShowImage("erode", erode);
    cv.Dilate(erode,erode, element2, 2) 
    return erode
end

local min_area = 1000

local function trackObject(destimg,imagethresh)

	local cont=cv.CreateSeq(0,cv.CvSeq["size"],cv.CvPoint["size"],storage)
   
	local mayor_area = 0
    local mayor_contorno = nil

	num_objects,contours=cv.FindContours(imagethresh,storage,cv.CvContour["size"],cv.CV_RETR_CCOMP,cv.CV_CHAIN_APPROX_SIMPLE,cv.Point(0,0))
	rng=cv.RNG(-1)
    if(contours) then 
		while contours do

			result=cv.ApproxPoly(contours,cv.CvContour["size"],storage,cv.CV_POLY_APPROX_DP, cv.ContourPerimeter(contours)*0.02,0)
			if ( cv.ContourArea(result,cv.Slice(0,result.total),0)> min_area and cv.CheckContourConvexity(result)) then
	         	color=cv.CV_RGB(cv.RandInt(rng)%255,cv.RandInt(rng)%255,cv.RandInt(rng)%255)
	            cv.DrawContours(destimg,result,color,cv.CV_RGB(cv.RandInt(rng)%255,cv.RandInt(rng)%255,cv.RandInt(rng)%255),result.total,3,cv.CV_AA,cv.Point(0,0))
	            local x_min, x_max =  cv.GetSeqElem(result,0,cv.CvPoint["name"]).x , cv.GetSeqElem(result,0,cv.CvPoint["name"]).x -- tomo como min y max el primer punto
	                
	            for i=0, result.total do
	                local pto = cv.GetSeqElem(result,i,cv.CvPoint["name"]) --devuelve un pto del contorno
	                 if pto.x <x_min then
	                    x_min = pto.x
	                 elseif pto.x > x_max then
	                    x_max = pto.x
	                 end
	            end
	                
	            local midd = ( x_min + x_max ) /2 
	            local size = cv.GetSize(destimg)
	            
	            cv.Line(destimg,cv.Point(midd,0),cv.Point(midd,size.height),color)
	            
	            if midd < (size.width * 0.4) then
	                print ("izquierda")
	            elseif midd > (size.width * 0.6) then
	                print ("derecha")
	            else
	                print ("centro")
	            end

	        local area_actual = cv.ContourArea(result,cv.Slice(0,result.total),0)
            if ( area_actual > min_area and cv.CheckContourConvexity(result)) then                    
                if area_actual > mayor_area then
                    mayor_area = area_actual
                    mayor_contorno = result
                end
            end 


        	end            
        	contours=contours.h_next
    	end

    end 
    return mayor_contorno 
end

local capture
capture = cv.CreateCameraCapture(1)

-- -- seteo el tamaño de camara
-- cv.SetCaptureProperty(capture, cv.CV_CAP_PROP_FRAME_WIDTH, 160)
-- cv.SetCaptureProperty(capture, cv.CV_CAP_PROP_FRAME_HEIGHT, 120)

cv.NamedWindow("imagen",1)

while (true) do
	if capture then
		frame = cv.QueryFrame(capture)
		imageHSV = cv.CreateImage(cv.GetSize(frame), cv.IPL_DEPTH_8U, 3)
		cv.CvtColor(frame, imageHSV, cv.CV_BGR2HSV)
		imageThres = cv.CreateImage(cv.GetSize(imageHSV), cv.IPL_DEPTH_8U, 1)
		cv.InRangeS(imageHSV, cv.Scalar(0,0, 200,0), cv.Scalar(180,255,255,0), imageThres) --busco color negro

		local imgtmp = morphOps(imageThres)
		local mayor_contorno = trackObject(frame,imgtmp)

		if mayor_contorno then

			local hull = cv.ConvexHull2(mayor_contorno, storage_hull, cv.CV_CLOCKWISE, 0);

			local pt0
			pt0=cv.GetSeqElem(hull,hull.total-1,cv.CvPoint["name"]..'[]')
			for i=0,hull.total do
		    	pt=cv.GetSeqElem(hull, i, cv.CvPoint["name"]..'[]')
		    	cv.Line(frame, pt0, pt, cv.CV_RGB(0,255,0), 1, cv.CV_AA,0)
		    	pt0=pt
	  		end

	  		local vct = {}
		    pt0=cv.GetSeqElem(hull,hull.total-1,cv.CvPoint["name"]..'[]')
		    for i=0,hull.total do
		        pt=cv.GetSeqElem(hull,i,cv.CvPoint["name"]..'[]')
		        vct[i] =pt
		    end

		    local mask = cv.CreateImage(cv.GetSize(frame), cv.IPL_DEPTH_8U, 1)
		    cv.FillConvexPoly(mask,vct,hull.total,cv.ScalarAll(255))

	  		imageZERO = cv.CreateImage(cv.GetSize(frame), cv.IPL_DEPTH_8U, 3)
	  		cv.Zero(imageZERO)
	  		cv.Copy(frame, imageZERO, mask)
	  		-- print (hull)
	  		-- cv.DrawContours(imageZERO, vct, cv.CV_RGB(255, 0, 0), cv.CV_RGB(255, 255, 255), 0, 1, 8)
			cv.ShowImage("imagen", imageZERO)
			cv.ReleaseImage(imageZERO)
	  	end
		
		cv.ReleaseImage(imgtmp)
		cv.ReleaseImage(frame)
		cv.ReleaseImage(imageThres)    
		cv.ReleaseImage(imageHSV)
	end

	if (cv.WaitKey(DELAY)==27) then break end

end
