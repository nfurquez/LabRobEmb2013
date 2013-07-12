local M = {}


local sched=require 'sched'
local toribio = require 'toribio'
local funcs_catalog = require 'catalog'.get_catalog('funcs')

M.init = function(conf)

local comportamientos = {}
local id_comp_prioridad_minima = 1
-- indice vector indica prioridad
-- vector[x].nombre
-- vector[x].esperando
-- vector[x].dar_un_paso

-- init del vector

comportamientos[1] = {}
comportamientos[1].nombre = 'adelante'
comportamientos[1].esperando = true --la tarea esta esperando por el control , ponemos true porque es la de menor prioridad
comportamientos[1].dar_un_paso = funcs_catalog:waitfor( 'adelante')

comportamientos[2] = {}
comportamientos[2].nombre = 'buscar_lata'
comportamientos[2].esperando = false --la tarea esta esperando por el control
comportamientos[2].dar_un_paso = funcs_catalog:waitfor('buscar_lata')

comportamientos[3] = {}
comportamientos[3].nombre = 'cargar_lata'
comportamientos[3].esperando = false --la tarea esta esperando por el control
comportamientos[3].dar_un_paso = funcs_catalog:waitfor('cargar_lata')

comportamientos[4] = {}
comportamientos[4].nombre = 'tirar_lata'
comportamientos[4].esperando = false --la tarea esta esperando por el control
comportamientos[4].dar_un_paso = funcs_catalog:waitfor('tirar_lata')

comportamientos[5] = {}
comportamientos[5].nombre = 'evitar_silla'
comportamientos[5].esperando = false --la tarea esta esperando por el control
comportamientos[5].dar_un_paso = funcs_catalog:waitfor('evitar_silla')

comportamientos[6] = {}
comportamientos[6].nombre = 'evitar_caer'
comportamientos[6].esperando = false --la tarea esta esperando por el control
comportamientos[6].dar_un_paso = funcs_catalog:waitfor('evitar_caer')
 

--local comps = { 'adelante','buscar_lata','cargar_lata','evitar_silla','evitar_caer'}

--[[
for i, com in ipairs(comps) do
    print (com,i)
    comportamientos[i] = {}
    comportamientos[i].name = com
    comportamientos[i].esperando = false --la tarea esta esperando por el control como es el de menor se le setea en true
    comportamientos[i].func = funcs_catalog:waitfor(com)
end
comportamientos[1].esperando = true --la tarea esta esperando por el control
]]

-- loop principal
sched.run(function()
-- @TODO espera de algo para arrancar
	--sched.sleep(5)
	
	--print("espero que cargue boton")
	-- local button =  toribio.wait_for_device('bb-button:'..conf.boton_stop)
   -- print("termino de cargar boton")
    
    
    local motors =  toribio.wait_for_device('bb-motors')
	-- while  button.getValue()  == 1 do
	--espera por el boton
	  --  print ("espera boton")
	--end
    local id_comp_corriendo = id_comp_prioridad_minima
     sched.sleep(5)
	sched.signal('start_signal')
	print('Envio de start_signal') 
 	
	while true do
	-- while  button.getValue()  == 1 do
	   local encontre = false
	   local id_com = #comportamientos
	   while (id_com >= 1) and not (encontre) do -- recorro de mayo id a menor id
	       
	        local table_com = comportamientos[id_com] --recibo id_com y su tabla asociada  
	        --print(id_com,table_com.ejecutando)
	        if table_com.esperando and (id_comp_corriendo < id_com) then --
	            table_com.esperando = false
	            encontre = true --encontre un comportamiento para darle el control
	            id_comp_corriendo =  id_com
	            --print('corriendo', id_comp_corriendo) 
	        elseif   table_com.esperando and (id_comp_corriendo == id_com) then
	            table_com.esperando = false
	            encontre = true --encontre un comportamiento para darle el control
	            id_comp_corriendo =  id_com
	           -- print('corriendo', id_comp_corriendo) 
	        elseif  not (comportamientos[id_comp_corriendo].esperando )and table_com.esperando and(id_comp_corriendo > id_com)  then --mayor 
	           	table_com.esperando = false
	            encontre = true --encontre un comportamiento para darle el control
	            id_comp_corriendo =  id_com
	           -- print('corriendo', id_comp_corriendo) 
	        end	
            id_com = id_com - 1       
		end
		
		if (not encontre )and (not  comportamientos[id_comp_corriendo].ejecutando ) then
		    -- ejecuto tarea menor prioridad
		    comportamientos[id_comp_prioridad_minima].esperando = false
            id_comp_corriendo =  id_comp_prioridad_minima
		     
		end
		--print(id_comp_corriendo)
		comportamientos[id_comp_corriendo].dar_un_paso()
		sched.yield()  
 
	end 
	motors.setvel2mtr(0, 0, 0, 0)
	print ('salir arbitro')
end)

--print ('--resto')
 
--- funcion para la espera por comportamientos 
local wait_espera = {emitter ='*',events ={'arbitro_espera'}}
sched.sigrun(wait_espera, function(_,_,nombre_emisor)
-- print('arbitro_espera'..nombre_emisor)
  for id_com,table_com in ipairs(comportamientos) do
    if table_com.nombre == nombre_emisor then
         table_com.esperando = true
         break
    end
 
 end
end)



--- funcion para los comportamientos que no esperan mas
local wait_no_espero = {emitter ='*',events ={'arbitro_no_espero'}}
sched.sigrun(wait_no_espero, function(_,_,nombre_emisor)
-- print('arbitro_no_espero'..nombre_emisor)
 for id_com,table_com in ipairs(comportamientos) do
    if table_com.nombre == nombre_emisor then
         table_com.esperando = false
         break
    end 
 end
end)
 

end

return M

