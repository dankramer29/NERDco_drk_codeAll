#!/bin/bash
# Starts SCL with NPTL parameters on Robox. Note that this should be copied to NPTL home directory on Robox so it can be called easily
# SDS June 2017
echo "Starting runExperiment.py nptl..."
cd scl-bmi/applications-linux/3DVisualization/
python runExperiment.py nptl