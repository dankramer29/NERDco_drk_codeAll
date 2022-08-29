#!/usr/bin/python

import redis

r = redis.StrictRedis(host='localhost', port=6379, db=0)

# populate intial keys

r.set('bmi_target_diameter', 0.1)
r.set('bmi_target_enabled', 1)
r.set('bmi_target_position', '0.5 0.1 0.1')
r.set('bmi_target_color', '0 1 0')
r.set('bmi_robot_state', 1)
r.set('bmi_decode_vel', '0 0 0')
r.set('bmi_decode_click', 0)
r.set('scl_pos_ee', '0.56 0 0.5')
r.set('scl_pos_ee_des', '0.56 0 0.5')
r.set('scl_time', 0)
r.set('scl_pos_ee_max', '0.6 0.4 0.92');
r.set('scl_pos_ee_min', '0.4 -0.4 0.11');
