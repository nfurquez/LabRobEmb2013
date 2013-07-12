#!/usr/bin/env lua
local cv=require('luacv')


local element = cv.CreateStructuringElementEx(3, 3, 1, 1, cv.CV_SHAPE_RECT)   
<<<<<<< HEAD
local element2 = cv.CreateStructuringElementEx(3, 3, 1, 1, cv.CV_SHAPE_RECT)
=======
local element2 = cv.CreateStructuringElementEx(5, 5, 1, 1, cv.CV_SHAPE_RECT)
>>>>>>> 041a7c0b410d7858285bac58553c304ac5227d17
local storage=cv.CreateMemStorage()

local function morphOps(imagethresh)

    erode = cv.CreateImage(cv.GetSize(imagethresh), cv.IPL_DEPTH_8U, 1)
    
    cv.Erode(imagethresh,erode, element, 1)
    
    -- cv.ShowImage("erode", erode);
    
     
    cv.Dilate(erode,erode, element2, 3)
    -- erode = imagethresh    

    
    return erode
end

<<<<<<< HEAD
local min_area = 1500
=======
local min_area = 500
>>>>>>> 041a7c0b410d7858285bac58553c304ac5227d17

local function trackObject(destimg,imagethresh)

  --  local tmp = cv.CreateImage(cv.GetSize(imagethresh), cv.IPL_DEPTH_8U, 1)
    local cont=cv.CreateSeq(0,cv.CvSeq["size"],cv.CvPoint["size"],storage)
    --local hierarchy = nil
   -- a,contours=cv.FindContours(imagethresh,storage,cv.CvContour["size"],cv.CV_RETR_CCOMP,cv.CV_CHAIN_APPROX_SIMPLE,cv.Point(0,0))
   
   num_objects,contours=cv.FindContours(imagethresh,storage,cv.CvContour["size"],cv.CV_RETR_CCOMP,cv.CV_CHAIN_APPROX_SIMPLE,cv.Point(0,0))
   rng=cv.RNG(-1)
    if(contours) then 
       --  print('contornos ',num_objects)
         while contours do
            --[[ result=cv.ApproxPoly(contours,cv.CvContour["size"],storage,cv.CV_POLY_APPROX_DP, cv.ContourPerimeter(contours)*0.02,0)
             if ( cv.ContourArea(result,cv.Slice(0,result.total),0)> min_area and cv.CheckContourConvexity(result)) then
                 --print (contours.total)
                 print('area',cv.ContourArea(result,cv.Slice(0,result.total),0))
                 for i =0, result.total do
                    cv.SeqPush(cont,cv.GetSeqElem(result,i,cv.CvPoint["name"])) 
                 end
                 
             end]]
            result=cv.ApproxPoly(contours,cv.CvContour["size"],storage,cv.CV_POLY_APPROX_DP, cv.ContourPerimeter(contours)*0.02,0)
             --if ( cv.ContourArea(result,cv.Slice(0,result.total),0)> min_area and cv.CheckContourConvexity(result)) then
             if ( cv.ContourArea(result,cv.Slice(0,result.total),0)> min_area ) then
                
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
                    --print
                
            end
           
             contours=contours.h_next
        end
    end
    return cont 
end


-- sin usar
function drawSeqs(img,squares)
  for i=0,squares.total-1,4 do
    rect={cv.GetSeqElem(squares,i,cv.CvPoint["name"]),
          cv.GetSeqElem(squares,i+1,cv.CvPoint["name"]),
          cv.GetSeqElem(squares,i+2,cv.CvPoint["name"]),
          cv.GetSeqElem(squares,i+3,cv.CvPoint["name"])}
    
    count={#rect}
    cv.PolyLine(img,rect,count,1,1,cv.CV_RGB(255,255,0),3,cv.CV_AA,0)
  end
 -- cv.ShowImage(wname,img)
 return imgf
end

local function equalizar(src)

local eqlimage=cv.CreateImage(cv.GetSize(src),cv.IPL_DEPTH_8U,3)
local  redImage=cv.CreateImage(cv.GetSize(src),cv.IPL_DEPTH_8U,1)
local  greenImage=cv.CreateImage(cv.GetSize(src),cv.IPL_DEPTH_8U,1)
local  blueImage=cv.CreateImage(cv.GetSize(src),cv.IPL_DEPTH_8U,1)
 cv.Split(src,blueImage,greenImage,redImage,None)
 cv.EqualizeHist(redImage,redImage)
 cv.EqualizeHist(greenImage,greenImage)
 cv.EqualizeHist(blueImage,blueImage)
 cv.Merge(blueImage,greenImage,redImage,None,eqlimage)     
    cv.ReleaseImage(redImage)
        cv.ReleaseImage(greenImage)
         cv.ReleaseImage(blueImage)       
return eqlimage

end
local capture

capture = cv.CreateCameraCapture(1)
local frame 
<<<<<<< HEAD
local H_MIN = 40
local H_MAX = 70
local S_MIN = 0
local S_MAX = 200
local V_MIN = 0
local V_MAX = 100

local DELAY = 5
=======
local H_MIN = 115
local H_MAX = 118
local S_MIN = 191
local S_MAX = 202
local V_MIN = 81
local V_MAX = 115
local   threshold_value = 0
local threshold_type = 3
local max_BINARY_value = 255

local DELAY =100
>>>>>>> 041a7c0b410d7858285bac58553c304ac5227d17
local ver_hsv = false
local ver_morf = false
local ver_track = true
local ver_filtro =true 

-- seteo el tamaño de camara
cv.SetCaptureProperty(capture, cv.CV_CAP_PROP_FRAME_WIDTH, 160);
cv.SetCaptureProperty(capture, cv.CV_CAP_PROP_FRAME_HEIGHT, 120);


wndname="barras"
cv.NamedWindow("original",1)
if ver_hsv  then cv.NamedWindow("HSV",1) end
if ver_morf then cv.NamedWindow("morf",1) end
if ver_track then cv.NamedWindow("track",1) end
if ver_filtro then cv.NamedWindow("filtro",1) end

cv.NamedWindow("thres",1)

--cv.NamedWindow("erode",1) 
cv.NamedWindow(wndname,1)

-- creo las barras 
cv.CreateTrackbar("H_MIN",wndname,179,function(i) H_MIN = i end)
cv.CreateTrackbar("H_MAX",wndname,179,function(i) H_MAX = i end)

cv.CreateTrackbar("S_MIN",wndname,255,function(i) S_MIN = i end)
cv.CreateTrackbar("S_MAX",wndname,255,function(i) S_MAX = i end)

cv.CreateTrackbar("V_MIN",wndname,255,function(i) V_MIN = i end)
cv.CreateTrackbar("V_MAX",wndname,255,function(i) V_MAX = i end)

cv.CreateTrackbar("thresh type",wndname,4,function(i) threshold_type = i end)
cv.CreateTrackbar("thresh value",wndname,255,function(i) threshold_value = i end)

--cv.CreateTrackbar("ERODE",wndname,10,function(i) if (i % 2)~=0  then element = cv.CreateStructuringElementEx(i,i, 1, 1, cv.CV_SHAPE_RECT)   end end)
--cv.CreateTrackbar("DILATE",wndname,10,function(i)if  (i% 2) ~=0  then  element2 = cv.CreateStructuringElementEx(i,i, 1, 1, cv.CV_SHAPE_RECT)  end end)

-- true si no capturo y obtengo desde una foto
local foto = false


while (true) do
  if capture then
   if not foto then
        frame = cv.QueryFrame(capture);
   else
    frame=cv.LoadImage('foto.jpg')
    local aux =  cv.CreateImage( cv.Size(160,120), cv.IPL_DEPTH_8U, 3)
    cv.Resize(frame, aux)
    cv.ReleaseImage(frame) 
    frame = aux
   end
    cv.ShowImage("original", frame);
<<<<<<< HEAD
    cv.Smooth(frame, frame, cv.CV_GAUSSIAN,3,3,0,0)
     
    imageHSV = cv.CreateImage(cv.GetSize(frame), cv.IPL_DEPTH_8U, 3)
    cv.CvtColor(frame, imageHSV, cv.CV_BGR2HSV);
    cv.Smooth(imageHSV, imageHSV, cv.CV_GAUSSIAN,3,3,0,0)
=======
    local equ = equalizar(frame)
       
    -- cv.Smooth(frame, frame, cv.CV_BLUR, 3)
    imageHSV = cv.CreateImage(cv.GetSize(frame), cv.IPL_DEPTH_8U, 3)
    cv.CvtColor(equ, imageHSV, cv.CV_BGR2HSV);
>>>>>>> 041a7c0b410d7858285bac58553c304ac5227d17
     if ver_hsv then   
        cv.ShowImage("HSV", imageHSV);
    end
    
    -- genera la binaria
    imageThres = cv.CreateImage(cv.GetSize(imageHSV), cv.IPL_DEPTH_8U, 1)
    cv.InRangeS(imageHSV, cv.Scalar(H_MIN,S_MIN, V_MIN,0), cv.Scalar(H_MAX,S_MAX,V_MAX,0), imageThres)

    if ver_filtro then
        cv.ShowImage("filtro", imageThres);
    end
    
    -- imagen erode + dilate
    if ver_morf then
        local imgtmp = morphOps(imageThres)
         cv.ShowImage("morf", imgtmp);
         cv.ReleaseImage(imgtmp)
    end
    
    -- trackeo mas imagen con rectangulo
    if ver_track then

        local imgtmp = morphOps(imageThres)
         cv.ShowImage("morf", imgtmp);
        --trackObject(frame,imageThres)
        trackObject(frame,imgtmp)
        cv.ShowImage("track", frame);
        cv.ReleaseImage(imgtmp)
    end
    
   
    cv.ShowImage("thres", equ);
    
    cv.ReleaseImage(equ)
    cv.ReleaseImage(frame)
  
    cv.ReleaseImage(imageThres)    
    cv.ReleaseImage(imageHSV)
    if foto then
        collectgarbage ("collect")
       cv.ReleaseImage(aux)
    end
  end
  if (cv.WaitKey(DELAY)==27) then break end
end


cv.ClearMemStorage(storage)
cv.DestroyAllWindows()
