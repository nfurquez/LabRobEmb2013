local M = {}


local sched = require 'sched'
local toribio = require 'toribio'
local funcs = require 'catalog'.get_catalog('funcs')

local  motors =  toribio.wait_for_device('bb-motors')  
local grises_izq
local grises_der

local tiempo_giro_atras  
local tiempo_adelante  
local valor_grises_caer  

local function cambiar_de_direccion()
--print('cambiar direccion ')
 --  motors.setvel2mtr(1, 0, 0, 0) --parar todo
   local gris_izq =grises_izq.getValue()
   local gris_der = grises_der.getValue()
   while gris_izq  > valor_grises_caer or gris_der > valor_grises_caer do
        if gris_der > valor_grises_caer then
             print('EVITAR CAER giro derecha')
                motors.setvel2mtr(0, 300, 0, 500)  
                sched.sleep(tiempo_giro_atras)
            	motors.setvel2mtr(0, 500, 1, 500) 
            	 
		    
		elseif gris_izq  > valor_grises_caer then
           print('EVITAR CAER  giro izquierda')
               motors.setvel2mtr(0, 500, 0, 300)  
               sched.sleep(tiempo_giro_atras)
               motors.setvel2mtr(1, 500, 0, 500)  
                
		   
		end
		sched.sleep(tiempo_adelante)
	    gris_izq =grises_izq.getValue()
        gris_der = grises_der.getValue() 
   end		
 --motors.setvel2mtr(1, 0, 0, 0) --parar todo
 print('cambiar direccion fin')
end

local  function sensar_grises()
	--print('sensar_grises')

		if grises_izq.getValue() > valor_grises_caer then  
			return true
		end
		if grises_der.getValue() > valor_grises_caer then  
			return true
		end
    return false
end


local comp_name ='evitar_caer'

local wait_arrancar = {emitter ='*',events={'start_signal'}}

M.init= function(conf)

tiempo_giro_atras = conf.tiempo_giro_atras  
tiempo_adelante  = conf.tiempo_adelante
valor_grises_caer = conf.valor_grises_caer 
   grises_izq =  toribio.wait_for_device('bb-grey:'..conf.gris_izq)
   grises_der =  toribio.wait_for_device('bb-grey:'..conf.gris_der)
 funcs:register(comp_name, cambiar_de_direccion)

sched.run(function()
   
    print('cargo '..comp_name)
    sched.wait(wait_arrancar)
    
   print('comienza '..comp_name)
    local nescesita_control  = false
    local pedi_control = false
    while true do
        nescesita_control = sensar_grises()
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
