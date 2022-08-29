#!/usr/bin/python

import os
import shutil

SESSION_DIR = '/cygdrive/e/Session'

directory_structure = [ 'Documents', 'Analysis', 'Data',
                        'Analysis/DecoderAnalysis', 'Analysis/FilterBuildFigs',
                        'Data/_Lateral', 'Data/_Medial', 'Data/FA', 'Data/FileLogger', 
                        'Data/Filters', 'Data/Filters/Discrete', 'Data/Filters/Components',
                        'Data/Log', 'Data/R', 'Data/stream', 'Data/Video',
                        'Data/Video/Audio', 'Data/Video/D3200/', 'Data/Video/XR550V',
                        'Software/params']

array_dirs = ['_Lateral', '_Medial']

cerebus_structure = [   'NSP Data', 'Screen Shots', 'System Tests',
                        'System Tests/Cross Talk', 'System Tests/Impedances']


raw_input('Press enter to begin delete')
						
# delete stuff
for i in directory_structure:

    to_del_dir = '%s/%s' % (SESSION_DIR, i)
    if os.path.exists(to_del_dir):

        shutil.rmtree(to_del_dir)
        print('deleted: %s' % to_del_dir) 


# build it back
for i in directory_structure:

    to_make_dir = '%s/%s' % (SESSION_DIR, i)
    if not os.path.exists(to_make_dir):
        os.mkdir(to_make_dir)
#        print('created: %s' % to_make_dir)

for i in cerebus_structure:

    for j in array_dirs:

        to_make_dir = '%s/Data/%s/%s' % (SESSION_DIR, j, i)
        if not os.path.exists(to_make_dir):
            os.mkdir(to_make_dir)
#            print('created: %s' % to_make_dir)

print('Directory structure recreated')
raw_input('Press enter to exit')