#!/bin/bash
source activate p27
cd /Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/LFADS/lfadsFromGIT
python run_lfads.py --kind=train \
--data_dir=/Users/frankwillett/Data/Monk/ \
--data_filename_stem=R_2016-02-02_1 \
--lfads_save_dir=/Users/frankwillett/Data/lfads_Jenkins_2016-02-02_1 \
--co_dim=0 \
--factors_dim=20 \
--ext_input_dim=0 \
--controller_input_lag=1 \
—-device=cpu:0 \