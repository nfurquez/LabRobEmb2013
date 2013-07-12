local M = {}

	local cv=require('luacv')
	M.morphOps = function(imagethresh, element, element2)
	    local erode = cv.CreateImage(cv.GetSize(imagethresh), cv.IPL_DEPTH_8U, 1)
	    cv.Erode(imagethresh,erode, element, 1)
	    cv.Dilate(erode,erode, element2, 2) 
	    return erode
	end

	M.contorno_mas_grande = function(imagethresh, min_area)
		local storage = cv.CreateMemStorage()
		local mayor_area = 0
	    local mayor_contorno = nil
	  	_,contours = cv.FindContours(imagethresh,storage,cv.CvContour["size"],cv.CV_RETR_CCOMP,cv.CV_CHAIN_APPROX_SIMPLE,cv.Point(0,0))
	    if(contours) then
	        while contours do
	            local result = cv.ApproxPoly(contours,cv.CvContour["size"],storage,cv.CV_POLY_APPROX_DP, cv.ContourPerimeter(contours)*0.02,0)
	            local area_actual = cv.ContourArea(result,cv.Slice(0,result.total),0)
	            if ( area_actual > min_area and cv.CheckContourConvexity(result)) then                    
	                if area_actual > mayor_area then
	                    mayor_area = area_actual
	                    mayor_contorno = result
	                end
	            end   
	            contours=contours.h_next
	        end    
	    end
	    cv.ReleaseMemStorage(storage)
	    return mayor_contorno
	end

	M.draw_cont = function(img,contours)
		local storage = cv.CreateMemStorage()
	    local result = cv.ApproxPoly(contours,cv.CvContour["size"],storage,cv.CV_POLY_APPROX_DP, cv.ContourPerimeter(contours)*0.02,0)   
	    local hull = cv.ConvexHull2(result,nil,cv.CV_CLOCKWISE,0);
	    local  mask = cv.CreateImage(cv.GetSize(img), cv.IPL_DEPTH_8U, 1)  
	    cv.Zero(mask)  
	    local vct = {}
	    pt0=cv.GetSeqElem(hull,hull.total-1,cv.CvPoint["name"]..'[]')
	    for i=0,hull.total do
	        pt=cv.GetSeqElem(hull,i,cv.CvPoint["name"]..'[]')
	        vct[i] =pt
	    end 

	    cv.FillConvexPoly(mask,vct,hull.total,cv.ScalarAll(255))

	    local return_image = cv.CreateImage(cv.GetSize(img), cv.IPL_DEPTH_8U, 3)
	    cv.Zero(return_image)
	    cv.Set(return_image, cv.CV_RGB(0,0,255));
	    cv.Copy(img, return_image, mask)
	    -- cv.ShowImage("coso", return_image);
	    cv.ReleaseImage(mask)

	    return return_image
	end

return M
