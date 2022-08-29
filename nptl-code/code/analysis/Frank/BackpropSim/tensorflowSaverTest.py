#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Tue Dec 12 23:12:05 2017

@author: frankwillett
"""
import scipy.io
import numpy as np
import tensorflow as tf
import argparse
import os
import errno
from customRnnCells import ContextGRUCell, ContextRNNCell, ContextLSTMCell, initializeWeights, makelambda

