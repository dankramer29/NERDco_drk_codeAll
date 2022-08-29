import tensorflow as tf
import numpy as np

def initializeWeights(shape, scale):
    initial = np.random.normal(0,1,shape)
    for i in range(shape[1]):
        initial[:,i] = scale * initial[:,i] / np.linalg.norm(initial[:,i])
        initial[:,i] = initial[:,i] / np.sqrt(shape[0])
    return initial.astype(np.float32)

class FirstOrderDecoder(tf.nn.rnn_cell.RNNCell):
  """
  Position, Velocity, or Acceleration decoder with first order (exponential) smoothing
  """
  def __init__(self, num_outputs, num_inputs, num_integrators, scope, weight_scale=1.0, nonlinear_gain=False):

    self._num_outputs = num_outputs
    self._num_inputs = num_inputs
    self._num_integrators = num_integrators
    
    self._weight_scale = weight_scale
    self._scope = scope
    self._nonlinear_gain = nonlinear_gain
    self._ng_units = 20
    
    with tf.variable_scope(self._scope):        
        #smoothing
        self.alpha = tf.get_variable("alpha", dtype=tf.float32, 0.94, trainable=True)
        
        #gain
        self.beta = tf.get_variable("beta", dtype=tf.float32, 1.0, trainable=True)
        
        #dimensionality reduction
        self.D = tf.get_variable("D", dtype=tf.float32, 
                initializer=initializeWeights([self.num_inputs, self.num_outputs], weight_scale), trainable=True)
        self.b = tf.get_variable("b", [1, self.num_outputs], dtype=tf.float32, 
                initializer=tf.zeros_initializer(), trainable=True)      
        
        #nonlinear gain
        if self._nonlinear_gain:
            self.W_ng_i = tf.get_variable("W_ng_i", dtype=tf.float32, 
                initializer=initializeWeights([1, self._ng_units], weight_scale), trainable=True)
            
            self.b_ng_i = tf.get_variable("b_ng_i", [1, self._ng_units], dtype=tf.float32, 
                initializer=tf.zeros_initializer(), trainable=True)
            
            self.W_ng_o = tf.get_variable("D", dtype=tf.float32, 
                initializer=initializeWeights([self.num_inputs, self.num_outputs], weight_scale), trainable=True)
            
  @property
  def state_size(self):
    return self.num_outputs

  @property
  def output_size(self):
    return self.num_outputs

  def __call__(self, inputs, state, scope=None):

    with tf.variable_scope(self._scope):
      batchSize = inputs.shape[0]
      new_state = tf.zeros([batchSize, self._num_outputs*(1+self._num_integrators)])    
      
      with tf.variable_scope("StateUpdate"): #state update
          new_state[:, 0:self._num_outputs] = state[:, 0:self._num_outputs]*self.alpha + (tf.matmul(inputs, self.D) + self.b)*(1-self.alpha)*self.beta
          if self._num_integrators==1:
              new_state[:, self._num_outputs:(self._num_outputs*2)] = new_state[:, self._num_outputs:(self._num_outputs*2)] + new_state[0:self._num_outputs]
          if self._num_integrators==2:
              new_state[:, (self._num_outputs*2):(self._num_outputs*3)] = new_state[:, (self._num_outputs*2):(self._num_outputs*3)] + new_state[:, self._num_outputs:(self._num_outputs*2)]
              
      outputs = new_state[:,(self._num_integrators*self._num_outputs):((self._num_integrators+1)*self._num_outputs)]
    
    return outputs, new_state

class StateSpaceDecoder(tf.nn.rnn_cell.RNNCell):
  """
  Linear state space decoder with more flexibility than LinearDecoder 
  """
  def __init__(self, num_outputs, num_inputs, num_integrators, scope):

    self._num_outputs = num_outputs
    self._num_inputs = num_inputs
    self._num_integrators = num_integrators
    
    self._reset_bias = reset_bias
    self._update_bias = update_bias
    self._weight_scale = weight_scale
    self._clip_value = clip_value
    self._scope = scope
    self._numContexts = numContexts
    self._contextIdx = contextIdx
    self._input_keep_prob = input_keep_prob
    
    with tf.variable_scope(self._scope):        
        #smoothing
        self.W = tf.get_variable("W", dtype=tf.float32, 
                initializer=initializeWeights([self._num_inputs, self._num_units], weight_scale), trainable=True)
        
        self.U = tf.get_variable("U", dtype=tf.float32, 
                initializer=initializeWeights([self._num_units, self._num_units ], weight_scale), trainable=True)
                        
        #generate context-dependent biases
        self._contextBiases = []
        
        for i in range(self._numContexts):   
            cb = tf.get_variable("cb_"+str(i), dtype=tf.float32, 
                                 initializer=initializeWeights([1, self._num_units], weight_scale), trainable=True)
            self._contextBiases.append(cb)
            
        #tf.case selects the appropriate context 
        pred = []
        for i in range(self._numContexts):   
            pred.append((tf.equal(contextIdx, tf.constant(i)), makelambda(self._contextBiases[i])))
        self.activeContextBias = tf.case(pred, default=makelambda(self._contextBiases[i]))
     
    self._weightVariables = [self.W, self.U]
    
  @property
  def state_size(self):
    return self._num_units

  @property
  def output_size(self):
    return self._num_units

  def __call__(self, inputs, state, scope=None):

    with tf.variable_scope(self._scope):
      #add dropout to inputs
      tf.nn.dropout(inputs, self._input_keep_prob)
          
      with tf.variable_scope("StateUpdate"): #state update
          new_h = tf.tanh(tf.matmul(inputs, self.W) + tf.matmul(state, self.U) + self.activeContextBias)
          
    return new_h, new_h