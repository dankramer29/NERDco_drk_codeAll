import tensorflow as tf
import numpy as np

def initializeWeights(shape, scale):
    initial = np.random.normal(0,1,shape)
    for i in range(shape[0]):
        initial[i,:] = scale * initial[i,:] / np.linalg.norm(initial[i,:])
        initial[i,:] = initial[i,:] / np.sqrt(shape[1])
    return initial.astype(np.float32)
    
class GRU(object):
  """
  Gated Recurrent Unit
  Following the algorithm and notation of: Empirical Evaluation of Gated Recurrent Neural Networks on Sequence Modeling
  arXiv:1412.3555v1 [cs.NE] 11 Dec 2014
  """
  def __init__(self, num_units, num_inputs, num_outputs, scope, 
               reset_bias=1.0, update_bias=-1.0, weight_scale=1.0,
               clip_value=np.inf, collections=None):

    self._num_units = num_units
    self._num_inputs = num_inputs
    self._num_outputs = num_outputs
    self._reset_bias = reset_bias
    self._update_bias = update_bias
    self._weight_scale = weight_scale
    self._clip_value = clip_value
    self._collections = collections
    self._scope = scope
    
    # We start with biases towards not resetting and not updating
    with tf.variable_scope(self._scope):
        #update gate variables (U_z, W_z, b_z) 
        self.W_z = tf.get_variable("W_z", dtype=tf.float32, 
                initializer=initializeWeights([self._num_units, self._num_inputs ], 1.0), trainable=True)
           
        self.U_z = tf.get_variable("U_z", dtype=tf.float32, 
                initializer=initializeWeights([self._num_units, self._num_units ], 1.0), trainable=True)
        
        self.b_z = tf.get_variable("b_z", [self._num_units, 1], dtype=tf.float32, 
                initializer=tf.constant_initializer(self._update_bias), trainable=True)
        
        #reset gate variables (W_r, U_r, b_r)
        self.W_r = tf.get_variable("W_r", dtype=tf.float32, 
                initializer=initializeWeights([self._num_units, self._num_inputs ], 1.0), trainable=True)
        
        self.U_r = tf.get_variable("U_r", dtype=tf.float32, 
                initializer=initializeWeights([self._num_units, self._num_units ], 1.0), trainable=True)
        
        self.b_r = tf.get_variable("b_r", [self._num_units, 1], dtype=tf.float32, 
                initializer=tf.constant_initializer(self._reset_bias), trainable=True)
        
        #candidate activation variables (W, U, b)
        self.W = tf.get_variable("W", dtype=tf.float32, 
                initializer=initializeWeights([self._num_units, self._num_inputs ], 1.0), trainable=True)
        
        self.U = tf.get_variable("U", dtype=tf.float32, 
                initializer=initializeWeights([self._num_units, self._num_units ], 1.0), trainable=True)
        
        self.b = tf.get_variable("b", [self._num_units, 1], dtype=tf.float32, 
                initializer=tf.zeros_initializer, trainable=True)
        
        #Output layer
        self.W_o = tf.get_variable("W_o", dtype=tf.float32, 
                initializer=initializeWeights([self._num_outputs, self._num_units ], 1.0), trainable=True)
        
        self.b_o = tf.get_variable("b_o", [self._num_outputs, 1], dtype=tf.float32, 
                initializer=tf.zeros_initializer, trainable=True)
         
  @property
  def state_size(self):
    return self._num_units

  @property
  def output_size(self):
    return self._num_units

  @property
  def state_multiplier(self):
    return 1

  def output_from_state(self, state):
    return state

  def __call__(self, inputs, state, scope=None):

    with tf.variable_scope(self._scope):
      with tf.variable_scope("Gates"):  # Reset gate and update gate.
        z = tf.sigmoid(tf.matmul(self.W_z, inputs) + tf.matmul(self.U_z, state) + self.b_z)
        r = tf.sigmoid(tf.matmul(self.W_r, inputs) + tf.matmul(self.U_r, state) + self.b_r)
        
      with tf.variable_scope("Candidate"): #Candidate state
        c = tf.tanh(tf.matmul(self.W, inputs) + tf.matmul(self.U, tf.multiply(r, state)) + self.b)
        
      with tf.variable_scope("StateUpdate"): #state update
          new_h = z * state + (1-z) * c
          new_h = tf.clip_by_value(new_h, -self._clip_value, self._clip_value)
      
      with tf.variable_scope("Output"): #outputs
          output = tf.matmul(self.W_o, new_h) + self.b_o
      
    return new_h, output, z, r