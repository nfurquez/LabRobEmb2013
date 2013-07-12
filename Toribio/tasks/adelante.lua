local M = {}


local sched = require 'sched'
local toribio = require 'toribio'
local funcs = require 'catalog'.get_catalog('funcs')


local motors 
local tiempo_giro
local cant_iter = 0
local carlitos_girala
local vel_giro 
local vel_adelante


function adelante()
   -- print (cant_iter)
	local izq
    local der
    if cant_iter == carlitos_girala then
        print('Giro random')
        izq = math.random(0, 1)
        if izq == 0 then
            der = 1
        else der = 0
        end
        motors.setvel2mtr(izq,  vel_giro , der,  vel_giro )
        sched.sleep(tiempo_giro)
        cant_iter = 0
    end
    motors.setvel2mtr(1, vel_adelante + 30, 1, vel_adelante)
    cant_iter = cant_iter + 1    
end


local comp_name ='adelante'

local wait_arrancar = {emitter ='*',events={'start_signal'}}

M.init = function (conf)

tiempo_giro = conf.tiempo_giro
carlitos_girala = conf.carlitos_girala
vel_giro = conf.velocidad_giro
vel_adelante = conf.velocidad_adelante 
 
sched.run(function()
    
    motors =  toribio.wait_for_device('bb-motors') 
    funcs:register(comp_name, adelante)

    print('cargo '..comp_name)
    sched.wait(wait_arrancar)
    
     local nescesita_control  = false
    local pedi_control = false
    while true do
        -- No hace nada porque es el de menor prioridad
        sched.yield()
    end
 

end)

--- funcion para resetear cant_iter
local wait_espera = {emitter ='*',events ={'arbitro_espera'}} --adelante nunca pide el control porque es de prioridad minima
sched.sigrun(wait_espera, function(_,_,nombre_emisor)
    cant_iter = 0 --si alguien pidio el procesador, espero mas tiempo para hacer giro_random
  
end)


end

return M
