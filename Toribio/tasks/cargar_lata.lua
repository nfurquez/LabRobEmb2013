local M = {}
local sched=require 'sched'
local funcs = require 'catalog'.get_catalog('funcs')
local toribio = require 'toribio'
local cv=require('luacv')

local motors = toribio.wait_for_device('bb-motors')
local camera = toribio.wait_for_device({module='camera'})

M.init = function(conf)

--- cambiar para que sea x conf
local H_MIN = conf.color_min.h
local H_MAX =conf.color_max.h
local S_MIN = conf.color_min.s
local S_MAX = conf.color_max.s
local V_MIN = conf.color_min.v
local V_MAX = conf.color_max.v

local element = cv.CreateStructuringElementEx(3, 3, 1, 1, cv.CV_SHAPE_RECT)   
local element2 = cv.CreateStructuringElementEx(3, 3, 1, 1, cv.CV_SHAPE_RECT)

local storage=cv.CreateMemStorage()

local min_area = conf.area_minima_lata
local velocidad_giro = conf.velocidad_giro
local velocidad_derecho = conf.velocidad_derecho


local comp_name ='cargar_lata'

local hay_lata_event = false

local min_zona_carga = conf.min_zona_carga
local  max_zona_carga = conf.max_zona_carga
--local sched=require 'sched'




--defino los eventos a esperar
local wait_arrancar = {emitter ='*',events={'start_signal'}}


local image = nil

-- registro callback de la camara
toribio.register_callback(camera, 'camevent', function()
   -- print ('callback lata')
           if (image ~= nil) then
               cv.ReleaseImage( image) 
           end
        
        image = camera.get_image()
        if image then
            cv.Smooth(image, image, cv.CV_GAUSSIAN,3,3,0,0)         
            local imageHSV = cv.CreateImage(cv.GetSize(image), cv.IPL_DEPTH_8U, 3)
            cv.CvtColor(image, imageHSV, cv.CV_BGR2HSV); 
            cv.Smooth(image, image, cv.CV_GAUSSIAN,3,3,0,0) 
            cv.ReleaseImage( image) -- no necesito mas la imagen
            image = cv.CreateImage(cv.GetSize(imageHSV), cv.IPL_DEPTH_8U, 1)
            cv.InRangeS(imageHSV, cv.Scalar(H_MIN,S_MIN, V_MIN,0), cv.Scalar(H_MAX,S_MAX,V_MAX,0), image)

            --  print('tengo imagen!')
            cv.ReleaseImage( imageHSV)         
        end
end)



local function morphOps(imagethresh)

    erode = cv.CreateImage(cv.GetSize(imagethresh), cv.IPL_DEPTH_8U, 1)
    
    cv.Erode(imagethresh,erode, element, 1)

    cv.Dilate(erode,erode, element2, 3)
 
    return erode
end



-- mi sensar es solo esperar a que buscar_lata tiene una lata en la zona de carga
local function sensar()
    return  hay_lata_event
end

--[[
local function trackObject(imagethresh)

    local cont=cv.CreateSeq(0,cv.CvSeq["size"],cv.CvPoint["size"],storage)
    
    num_objects,contours=cv.FindContours(imagethresh,storage,cv.CvContour["size"],cv.CV_RETR_CCOMP,cv.CV_CHAIN_APPROX_SIMPLE,cv.Point(0,0))
    if(contours) then
        local mayor_area = 0
        local mayor_contorno = nil
        while contours do
            result=cv.ApproxPoly(contours,cv.CvContour["size"],storage,cv.CV_POLY_APPROX_DP, cv.ContourPerimeter(contours)*0.02,0)
            local area_actual = cv.ContourArea(result,cv.Slice(0,result.total),0)
            if ( area_actual > min_area and cv.CheckContourConvexity(result)) then                    
                if area_actual > mayor_area then
                    mayor_area = area_actual
                    mayor_contorno = result
                end
            end   
            contours=contours.h_next
        end    

        if mayor_contorno then 
            local y_min, y_max =  cv.GetSeqElem(mayor_contorno,0,cv.CvPoint["name"]).y , cv.GetSeqElem(mayor_contorno,0,cv.CvPoint["name"]).y -- tomo como min y max el primer punto
                    
            for i=0, result.total do
                local pto = cv.GetSeqElem(mayor_contorno,i,cv.CvPoint["name"]) --devuelve un pto del contorno
                 if pto.y <y_min then
                    y_min = pto.y
                 elseif pto.y > y_max then
                    y_max = pto.y
                 end
            end
                
            local midd = ( y_min + y_max ) /2 
            
            local size = cv.GetSize(imagethresh)                
            
            -- devuelvo true si estoy dentro de la zona de carga
            if (midd > size.height * min_zona_carga)  and (midd < size.height * max_zona_carga)then
                return true
            else
                return false
            end
            
        end    
         
    end
    return false
end
]]



local function findObject(imagethresh)

   -- local tmp = cv.CreateImage(cv.GetSize(imagethresh), cv.IPL_DEPTH_8U, 1)
    --local cont=cv.CreateSeq(0,cv.CvSeq["size"],cv.CvPoint["size"],storage)
    encontre = false
   _,contours=cv.FindContours(imagethresh,storage,cv.CvContour["size"],cv.CV_RETR_CCOMP,cv.CV_CHAIN_APPROX_SIMPLE,cv.Point(0,0))
    if(contours) then 
        
         while contours and (not encontre ) do

            result=cv.ApproxPoly(contours,cv.CvContour["size"],storage,cv.CV_POLY_APPROX_DP, cv.ContourPerimeter(contours)*0.02,0)
            if ( cv.ContourArea(result,cv.Slice(0,result.total),0)> min_area and cv.CheckContourConvexity(result)) then

                encontre = true
                
            end            
             contours=contours.h_next
        end
       
    end
    --cv.ReleaseImage(tmp) 
    return encontre 
end


local function dar_un_paso()

-- PARO LOS MOTORES 
 motors.setvel2mtr(0, 0, 1, 0)
 
-- lo seteo para que no lo pida mas
hay_lata_event =false
--[[
-- centro mejor la lata
local centrando = true
while centrando do

if image then
        local imgtmp = morphOps(image)
        centrando =not trackObject(imgtmp) 
        cv.ReleaseImage(imgtmp)
end
end]]

-- cargo la lata, me muevo mientras tenga la lata adelante
local esta_lata_en_zona = true

    while esta_lata_en_zona do
        if image then
                local imgtmp = morphOps(image)
                --esta_lata_en_zona = trackObject(imgtmp)
                 esta_lata_en_zona = findObject(imgtmp)
                cv.ReleaseImage(imgtmp)
            for i = 0, 2 do
                motors.setvel2mtr(0, 200, 1, 200) --girar a la izquierda sobre el eje
                motors.setvel2mtr(1, 200, 0, 200) --girar a la derecha sobre el eje
            end
            motors.setvel2mtr(0, 0, 0, 0) --paro los motores
        end
        sched.yield()
    end

cv.ClearMemStorage(storage)    
-- ya no esta la lata porque la "cargue"  
sched.signal('lata_cargada')
hay_lata_event =false
end


sched.run(function()

funcs:register(comp_name, dar_un_paso)

    print('cargo '..comp_name)

    sched.wait(wait_arrancar)    
    print('comienza '..comp_name)
    local nescesita_control  = false
    local pedi_control = false
    while true do
        nescesita_control = sensar()
        if nescesita_control then
            sched.signal('arbitro_espera',comp_name)
            pedi_control = true
        elseif pedi_control then --entro cuando ya no necesito el control pero lo pedi anteriormenete y no me lo dieron
             sched.signal('arbitro_no_espero',comp_name)
             pedi_control = false
        end        
        sched.yield()
    end


end)


--- avisa que hay lata y cambio la bandera
local wait_cargar_lata= {emitter ='*',events ={'cargar_lata_hay_lata'}}
sched.sigrun(wait_cargar_lata, function(_,_)
print('carga lata!!')
     hay_lata_event = true
end)




end

return M
