#!/usr/bin/env lua
local cv=require('luacv')


local frame 
local H_MIN = 0
local H_MAX = 180
local S_MIN = 0
local S_MAX = 150
local V_MIN = 130
local V_MAX = 255


local capture
local storage=cv.CreateMemStorage()
local DELAY = 5
capture = cv.CreateCameraCapture(1)
cv.NamedWindow("original",1)
cv.NamedWindow("coso",1)

 function contorno_mas_grande(imagethresh)
    local mayor_area = 0
    local mayor_contorno = nil
    local seq = cv.CreateSeq(cv.CV_32SC2["value"],cv.CvContour["size"],cv.CvPoint["size"],storage)
  _,contours=cv.FindContours(imagethresh,storage,cv.CvContour["size"],cv.CV_RETR_TREE,cv.CV_CHAIN_APPROX_SIMPLE,cv.Point(0,0))
    if(contours) then
     
        while contours do
            -- result=cv.ApproxPoly(contours,cv.CvContour["size"],storage,cv.CV_POLY_APPROX_DP, cv.ContourPerimeter(contours)*0.02,0)
            -- local area_actual = cv.ContourArea(result,cv.Slice(0,result.total),0)
            -- if ( area_actual > 2000 ) then                    
            --     if area_actual > mayor_area then
            --         mayor_area = area_actual
            --         mayor_contorno = result
            --     end
            -- end
            
            result=cv.ApproxPoly(contours,cv.CvContour["size"],storage,cv.CV_POLY_APPROX_DP, cv.ContourPerimeter(contours)*0.02,0)
            for i=0, result.total do
                local pto = cv.GetSeqElem(result,i,cv.CvPoint["name"]) --devuelve un pto del contorno
                cv.SeqInsert(seq,0,pto)
            end

            contours=contours.h_next
        end    
    end
    
    return seq
end

function draw_cont(img,contours)

    -- print(contours)
    -- result=cv.ApproxPoly(contours,cv.CvContour["size"],storage,cv.CV_POLY_APPROX_DP, cv.ContourPerimeter(contours)*0.02,0)   
    hull=cv.ConvexHull2(contours,nil,cv.CV_CLOCKWISE,0);
    local  aux = cv.CreateImage(cv.GetSize(img), cv.IPL_DEPTH_8U, 1)  
    cv.Zero(aux)  
    local vct = {}
    pt0=cv.GetSeqElem(hull,hull.total-1,cv.CvPoint["name"]..'[]')
    print(hull.total)
    for i=0,hull.total do
        pt=cv.GetSeqElem(hull,i,cv.CvPoint["name"]..'[]')
       -- cv.Line(aux,pt0,pt,cv.CV_RGB(255,255,255),cv.CV_AA,0)
        --pt0=pt
        vct[i] =pt
    end 

    cv.FillConvexPoly(aux,vct,hull.total,cv.ScalarAll(255))

   -- local _,cont=cv.FindContours(aux,storage,cv.CvContour["size"],cv.CV_RETR_CCOMP,cv.CV_CHAIN_APPROX_SIMPLE,cv.Point(0,0))

   -- cont=cv.ApproxPoly(cont,cv.CvContour["size"],storage,cv.CV_POLY_APPROX_DP, cv.ContourPerimeter(cont)*0.02,0)

    local crop = cv.CreateImage(cv.GetSize(img), cv.IPL_DEPTH_8U, 3)
    cv.Zero(crop)
    -- cv.Set(crop, cv.CV_RGB(0,255,0));
    cv.Copy(img,crop,aux)

    cv.ShowImage("coso", crop);
    cv.ReleaseImage(aux)
    cv.ReleaseImage(crop)

end

while (true) do
  if capture then
    frame = cv.QueryFrame(capture);
    if frame then
        local size = cv.GetSize(frame)
    --cv.Line(frame,cv.Point(0,0),cv.Point(size.width,0),color)
    cv.Line(frame,cv.Point(0,0),cv.Point(size.width,0),cv.CV_RGB(0,0,255),20,cv.CV_AA,0)
     imageHSV = cv.CreateImage(cv.GetSize(frame), cv.IPL_DEPTH_8U, 3)
    cv.CvtColor(frame, imageHSV, cv.CV_BGR2HSV);
    imageThres = cv.CreateImage(cv.GetSize(imageHSV), cv.IPL_DEPTH_8U, 1)
    cv.InRangeS(imageHSV, cv.Scalar(H_MIN,S_MIN, V_MIN,0), cv.Scalar(H_MAX,S_MAX,V_MAX,0), imageThres)
     
    cont = contorno_mas_grande(imageThres)
    if cont ~= nil then
     draw_cont(frame ,cont)
    end
    cv.ShowImage("original", frame);
   
    cv.ReleaseImage(frame) 

    cv.ReleaseImage(imageThres)    
    cv.ReleaseImage(imageHSV)
    cv.ClearMemStorage(storage)
    end
  end
  if (cv.WaitKey(DELAY)==27) then break end
end
 
cv.ReleaseMemStorage(storage)
cv.DestroyAllWindows()
