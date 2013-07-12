---
-- A test program with two tasks, one emitting signals and the other accepting them.
--See how fast it can run.

--look for packages one folder up.
package.path = package.path .. ";;;../?.lua"

local sched = require "sched"

sched.sigrun({emitter='*', events={sched.EVENT_DIE}}, print)

print('Starting a few tasks')

local function run_attached(f)
	local task=sched.new_task(f)
	task:set_as_attached()
	return task:run()
end

local emitter_task=sched.run(function()
	run_attached(function()
		print ('1')
		run_attached(function()
			print ('1.1')
			run_attached(function()
				print ('1.1.1')
				sched.sleep(10)
			end)
			sched.sleep(10)
		end)
		run_attached(function()
			print ('1.2')
			sched.sleep(10)
		end)

		sched.sleep(10)
	end)
	sched.sleep(10)
end)

sched.run(function()
	sched.sleep(2)
	print('Killing root task', emitter_task)
	emitter_task:kill()
end)

sched.go()
