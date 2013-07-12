swapon /dev/mmcblk0p4 

v4l2-ctl --set-ctrl white_balance_temperature_auto=1
v4l2-ctl --set-parm = 30
lua toribio-go.lua -c arbitro.conf

#swapoff /dev/mmcblk0p4
python stop.py 
