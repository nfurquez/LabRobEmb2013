#!/usr/bin/env lua
cv=require('luacv')

local capture;


capture = cv.CreateCameraCapture(0)
--cv.SetCaptureProperty(capture, cv.CV_CAP_PROP_FRAME_WIDTH, 160);
--cv.SetCaptureProperty(capture, cv.CV_CAP_PROP_FRAME_HEIGHT, 120);

cv.SetCaptureProperty(capture, cv.CV_CAP_PROP_FRAME_WIDTH, 320);
cv.SetCaptureProperty(capture, cv.CV_CAP_PROP_FRAME_HEIGHT, 240);



local DELAY=5
local imgThresh = nil


local function countPixels(img, minHue, maxHue, minSaturation, maxSaturation, minValue, maxValue)
    cv.Smooth(img, img, cv.CV_GAUSSIAN,1,1,0,0)
    local imageHSV = cv.CreateImage(cv.GetSize(img), cv.IPL_DEPTH_8U, 3);
    cv.CvtColor(img, imageHSV, cv.CV_BGR2HSV);
    local imgThresh = cv.CreateImage(cv.GetSize(imageHSV), cv.IPL_DEPTH_8U, 1);
    cv.InRangeS(imageHSV, cv.Scalar(minHue,minSaturation,minValue,0), cv.Scalar(maxHue,maxSaturation,maxValue,0), imgThresh);
    --cv.Smooth(imgThresh, imgThresh, cv.CV_GAUSSIAN,9,9,0,0);
    --cv.Smooth(imgThresh, imgThresh, cv.CV_GAUSSIAN,9,9,0,0);
    
    local pixel_count = cv.CountNonZero(imgThresh)
    
    return pixel_count, imgThresh;
end

cv.NamedWindow("cam-test",1)
cv.NamedWindow("cam-test2",1)
while (true) do

    if capture then
        
        
       -- local fps = cv.GetCaptureProperty(capture, cv.CV_CAP_PROP_FPS);
       -- print (fps)
        frame = cv.QueryFrame(capture);
        image = cv.CreateImage( cv.GetSize(frame), cv.IPL_DEPTH_8U, 3 )
        cv.Copy( frame, image)
        if image then
            --cv.Smooth(image, image, cv.CV_GAUSSIAN,11,11,0,0)
            --imageHSV = cv.CreateImage(cv.GetSize(image), cv.IPL_DEPTH_8U, 3)
            --cv.CvtColor(image, imageHSV, cv.CV_BGR2HSV);
            --imgThresh = cv.CreateImage(cv.GetSize(image), cv.IPL_DEPTH_8U, 1)
            --cv.InRangeS(imageHSV, cv.Scalar(0,60,0,0), cv.Scalar(179,200,50,0), imgThresh)
            --cv.Smooth(imgThresh, imgThresh, cv.CV_GAUSSIAN,9,9,0,0)
            
            --contornos = cv.CreateImage(cv.GetSize(imgThresh), cv.IPL_DEPTH_8U, 1)
            --cv.CvtColor(image,imgThresh,cv.CV_BGR2GRAY)
            
            
            local pixel_count, contornos = countPixels(image, 0, 179, 60, 200, 0, 50);
            --print("Cantidad de pixeles: ", pixel_count);
            
            local pos = 1
            local element = cv.CreateStructuringElementEx(pos*2+1, pos*2+1, pos, pos, cv.CV_SHAPE_RECT)            
            --cv.Threshold(contornos, contornos, 100, 255, cv.CV_THRESH_BINARY)
            cv.Dilate(contornos,contornos, element, 15)
            
            
            
            --local objeto = (CvRect*) cv.GetSeqElem() 
            
            --cv.Erode(contornos,contornos, element, 3)
            --cv.Smooth(contornos, contornos, cv.CV_GAUSSIAN,11,11,0,0)
           
            --cv.Canny(imgThresh, contornos, 10, 50, 3)
            
            --cv.ShowImage("cam-test", contornos)
            cv.ShowImage("cam-test", contornos);
            cv.ShowImage("cam-test2", image);
            
            if (cv.WaitKey(DELAY)==27) then break end

            
            cv.ReleaseImage(image)
            --cv.ReleaseImage(imageHSV)
            cv.ReleaseImage(contornos)
        end
    end

end

cv.DestroyAllWindows()
