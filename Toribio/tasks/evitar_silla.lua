local M = {}
local sched=require 'sched'
local funcs = require 'catalog'.get_catalog('funcs')
local toribio = require 'toribio'
local cv=require('luacv')

local motors = toribio.wait_for_device('bb-motors')
local camera = toribio.wait_for_device({module='camera'})
local dist
M.init = function(conf)

dist = toribio.wait_for_device('bb-distanc:'..conf.id_dist)

local min_dist_silla = conf.min_dist_silla

local H_MIN = conf.color_min.h
local H_MAX = conf.color_max.h
local S_MIN = conf.color_min.s
local S_MAX = conf.color_max.s
local V_MIN = conf.color_min.v
local V_MAX = conf.color_max.v

local element = cv.CreateStructuringElementEx(3, 3, 1, 1, cv.CV_SHAPE_RECT)   
local element2 = cv.CreateStructuringElementEx(3, 3, 1, 1, cv.CV_SHAPE_RECT)

local storage = cv.CreateMemStorage() --para calcular los contornos

local min_area = conf.area_minima_silla
local velocidad_giro = conf.velocidad_giro
local tiempo_giro_esquivar = conf.tiempo_giro_esquivar
local tiempo_giro_maniobras = conf.tiempo_giro_maniobras
local tiempo_atras_maniobras = conf.tiempo_atras_maniobras

local limite_horizontal= conf.limite_horizontal


local comp_name ='evitar_silla'

--defino los eventos a esperar
local wait_arrancar = {emitter ='*',events={'start_signal'}}


local image = nil

-- registro callback de la camara, genera la imagen binaria que voy a procesar luego
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



local function findObject(imagethresh)

    
    --local cont=cv.CreateSeq(0,cv.CvSeq["size"],cv.CvPoint["size"],storage)
    encontre = false
    local _,contours=cv.FindContours(imagethresh,storage,cv.CvContour["size"],cv.CV_RETR_CCOMP,cv.CV_CHAIN_APPROX_SIMPLE,cv.Point(0,0))
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
            local  y_max =  cv.GetSeqElem(mayor_contorno,0,cv.CvPoint["name"]).y  -- tomo como max el primer punto
                    
            for i=0, mayor_contorno.total do
                local pto = cv.GetSeqElem(mayor_contorno,i,cv.CvPoint["name"]) --devuelve un pto del contorno
                               
                 if pto.y > y_max then
                    y_max  = pto.y
                 end
            end
            
            local size = cv.GetSize(imagethresh)
            
           -- print('mid y', midd_y)
            
            if y_max >= size.height * limite_horizontal then
                  return true
            else
                return false
            
            end
            
        end    
         
    end
   
    return false 
end




local function sensar()
 if image then
    if dist.getValue() > min_dist_silla then
    
        return true
    end
    
    local imgtmp = morphOps(image)

    local encontre = findObject(imgtmp)
    cv.ReleaseImage(imgtmp)
    cv.ClearMemStorage(storage) 
    return encontre
 else
    return false
 end
end


local function trackObject(imagethresh)

   -- local cont=cv.CreateSeq(0,cv.CvSeq["size"],cv.CvPoint["size"],storage)
    
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
            local x_min, x_max =  cv.GetSeqElem(mayor_contorno,0,cv.CvPoint["name"]).x , cv.GetSeqElem(mayor_contorno,0,cv.CvPoint["name"]).x -- tomo como min y max el primer punto
                    
            for i=0, result.total do
                local pto = cv.GetSeqElem(mayor_contorno,i,cv.CvPoint["name"]) --devuelve un pto del contorno
                 if pto.x <x_min then
                    x_min = pto.x
                 elseif pto.x > x_max then
                    x_max = pto.x
                 end
                 
            end
                         
            local midd = ( x_min + x_max ) /2
            
            local size = cv.GetSize(imagethresh)
                            
            
           if midd < (size.width * 0.50) then
                return 0 -- print ("izquierda")
           else
                return 1 --print ("derecha")
            end  
            
        end    
         
    end
   return -1  
end


local function dar_un_paso()

--print('cosas con imagen')

    if image then
         if dist.getValue() > min_dist_silla then
         -- COmo tengo la silla de frente tengo que hacer un giro de grande
             print("SILLA maniobras evasivas")
             motors.setvel2mtr(0, velocidad_giro, 0, velocidad_giro) --Voy hacia atras
             sched.sleep(tiempo_atras_maniobras)
             motors.setvel2mtr(1, velocidad_giro, 0, velocidad_giro) --girar a la derecha sobre el eje
             sched.sleep(tiempo_giro_maniobras)
         else        
        -- Como no tengo la silla de frente me voy moviendo de a poco para esquivar la silla
        
            local imgtmp = morphOps(image)

            local direccion = trackObject(imgtmp)

            sched.yield()

          --  local direccion = trackObject(imgtmp) -- descomentar esta y comentar arriba
            if direccion == 0 then
                print("SILLA giro a la derecha")
                motors.setvel2mtr(1, velocidad_giro, 0, velocidad_giro) --girar a la derecha sobre el eje
                sched.sleep(tiempo_giro_esquivar)
            elseif direccion == 1 then
                print("SILLA giro a la izquierda")
                motors.setvel2mtr(0,velocidad_giro, 1, velocidad_giro) --girar a la izquierda sobre el eje
                sched.sleep(tiempo_giro_esquivar)
            else
                print("error: contours = null")
            end
            
            cv.ReleaseImage(imgtmp) 
            cv.ClearMemStorage(storage)    
         end   
    end

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



end

return M
