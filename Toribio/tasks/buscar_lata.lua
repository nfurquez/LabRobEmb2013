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
local H_MAX = conf.color_max.h
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

local limite_derecha = conf.limite_derecha
local limite_izquierda =conf.limite_izquierda

local zona_de_carga = conf.zona_de_carga -- descomentar para cargar_lata

local comp_name ='buscar_lata'






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



local function findObject(imagethresh)

    --local tmp = cv.CreateImage(cv.GetSize(imagethresh), cv.IPL_DEPTH_8U, 1)
   -- local cont=cv.CreateSeq(0,cv.CvSeq["size"],cv.CvPoint["size"],storage)
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
   -- cv.ReleaseImage(tmp) 
    return encontre 
end




local function sensar()
 -- print ('senso lata')
 if image then
  
    local imgtmp = morphOps(image)

    local encontre = findObject(imgtmp)
    cv.ReleaseImage(imgtmp) 
    
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
           
            local y_min, y_max =  cv.GetSeqElem(mayor_contorno,0,cv.CvPoint["name"]).y , cv.GetSeqElem(mayor_contorno,0,cv.CvPoint["name"]).y -- tomo como min y max el primer punto
                    
            for i=0, mayor_contorno.total do
                local pto = cv.GetSeqElem(mayor_contorno,i,cv.CvPoint["name"]) --devuelve un pto del contorno
                 if pto.x <x_min then
                    x_min = pto.x
                 elseif pto.x > x_max then
                    x_max = pto.x
                 end
                  
                  
                  if pto.y <y_min then
                    y_min = pto.y
                 elseif pto.y > y_max then
                    y_max = pto.y
                 end
                 
                 
            end
                         
            local midd = ( x_min + x_max ) /2
          
            local midd_y = ( y_min + y_max ) /2 -- descomentar para cargar_lata
            en_zona = false  -- descomentar para cargar_lata
            
            
            local size = cv.GetSize(imagethresh)
            

            
            if midd_y > size.height * zona_de_carga then 
                    en_zona = true
                 end 
           
          
             -- descomentar este y comentar el de arriba            
            if midd < (size.width * limite_izquierda) then
                return 0, en_zona    -- print ("izquierda")
            elseif midd > (size.width * limite_derecha) then
                return 1, en_zona --print ("derecha")
            else
                return 2, en_zona --print ("centro")
            end  
            
            
            
        end    
         
    end
   -- return -1 --, false 
    return -1 , false -- descomentar para cargar_lata y comentar arriba
end



local function dar_un_paso()

--print('cosas con imagen')

    if image then
        local imgtmp = morphOps(image)

        local direccion = trackObject(imgtmp)
        local direccion, en_zona = trackObject(imgtmp) -- descomentar esta y comentar arriba

        sched.yield()

        if direccion == 0 then
            print("Veo lata, giro a la izquierda")
            motors.setvel2mtr(0, velocidad_giro, 1, velocidad_giro) --girar a la izquierda sobre el eje
            --sched.sleep(0.1)
        elseif direccion == 1 then
            print("Veo lata, giro a la derecha")
            motors.setvel2mtr(1,velocidad_giro, 0, velocidad_giro) --girar a la derecha sobre el eje
            --sched.sleep(0.1)
        elseif direccion == 2 then
            print("Veo lata, sigo al centro")
            motors.setvel2mtr(1, velocidad_derecho, 1, velocidad_derecho) --voy para adelante
            --sched.sleep(0.1)
        else
            print("error: contours = null")
        end
        
        cv.ReleaseImage(imgtmp)
      
          -- descomentar para el cargar lata
       if en_zona then
            print('en zona')
             sched.signal('cargar_lata_hay_lata')
              motors.setvel2mtr(1, 0, 1,0)
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
