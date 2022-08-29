import tensorflow as tf
import numpy as np

def initializeWeights(shape, scale):
    initial = np.random.normal(0,1,shape)
    for i in range(shape[1]):
        initial[:,i] = scale * initial[:,i] / np.linalg.norm(initial[:,i])
        initial[:,i] = initial[:,i] / np.sqrt(shape[0])
    return initial.astype(np.float32)

def makelambda(v):          # Used with tf.case
  return lambda: v
    
class ContextGRUCell(tf.nn.rnn_cell.RNNCell):
  """
  Gated Recurrent Unit
  Following the algorithm and notation of: Empirical Evaluation of Gated Recurrent Neural Networks on Sequence Modeling
  arXiv:1412.3555v1 [cs.NE] 11 Dec 2014
  """
  def __init__(self, num_units, num_inputs, scope, contextIdx, input_keep_prob=1.0, numContexts=1,
               reset_bias=1.0, update_bias=-1.0, weight_scale=1.0,
               clip_value=np.inf, collections=None):

    self._num_units = num_units
    self._num_inputs = num_inputs
    self._reset_bias = reset_bias
    self._update_bias = update_bias
    self._weight_scale = weight_scale
    self._clip_value = clip_value
    self._scope = scope
    self._numContexts = numContexts
    self._contextIdx = contextIdx
    self._input_keep_prob = input_keep_prob
    
    with tf.variable_scope(self._scope):
        #update gate variables (U_z, W_z, b_z) 
        self.W_z = tf.get_variable("W_z", dtype=tf.float32, 
                initializer=initializeWeights([self._num_inputs, self._num_units ], weight_scale), trainable=True)
           
        self.U_z = tf.get_variable("U_z", dtype=tf.float32, 
                initializer=initializeWeights([self._num_units, self._num_units ], weight_scale), trainable=True)
        
        self.b_z = tf.get_variable("b_z", [1, self._num_units], dtype=tf.float32, 
                initializer=tf.constant_initializer(self._update_bias), trainable=True)
        
        #reset gate variables (W_r, U_r, b_r)
        self.W_r = tf.get_variable("W_r", dtype=tf.float32, 
                initializer=initializeWeights([self._num_inputs, self._num_units ], weight_scale), trainable=True)
        
        self.U_r = tf.get_variable("U_r", dtype=tf.float32, 
                initializer=initializeWeights([self._num_units, self._num_units ], weight_scale), trainable=True)
        
        self.b_r = tf.get_variable("b_r", [1, self._num_units], dtype=tf.float32, 
                initializer=tf.constant_initializer(self._reset_bias), trainable=True)
        
        #candidate activation variables (W, U, b)
        self.W = tf.get_variable("W", dtype=tf.float32, 
                initializer=initializeWeights([self._num_inputs, self._num_units], weight_scale), trainable=True)
        
        self.U = tf.get_variable("U", dtype=tf.float32, 
                initializer=initializeWeights([self._num_units, self._num_units ], weight_scale), trainable=True)
        
        self.b = tf.get_variable("b", [1, self._num_units], dtype=tf.float32, 
                initializer=tf.zeros_initializer, trainable=True)
       
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
        
    self._weightVariables = [self.W_z, self.U_z, self.W_r, self.U_r, self.W, self.U]
    
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
          
      with tf.variable_scope("Gates"):  # Reset gate and update gate.
        z = tf.sigmoid(tf.matmul(inputs, self.W_z) + tf.matmul(state, self.U_z) + self.b_z)
        r = tf.sigmoid(tf.matmul(inputs, self.W_r) + tf.matmul(state, self.U_r) + self.b_r)
        
      with tf.variable_scope("Candidate"): #Candidate state
        c = tf.tanh(tf.matmul(inputs, self.W) + tf.matmul(tf.multiply(r, state), self.U) + self.activeContextBias)
        
      with tf.variable_scope("StateUpdate"): #state update
          new_h = z * state + (1-z) * c
          new_h = tf.clip_by_value(new_h, -self._clip_value, self._clip_value)
            
    return new_h, new_h

class ContextRNNCell(tf.nn.rnn_cell.RNNCell):
  """
  Vanilla tanh RNN
  """
  def __init__(self, num_units, num_inputs, scope, contextIdx, numContexts=1,
               input_keep_prob=1.0, reset_bias=1.0, update_bias=-1.0, weight_scale=1.0,
               clip_value=np.inf, collections=None):

    self._num_units = num_units
    self._num_inputs = num_inputs
    self._reset_bias = reset_bias
    self._update_bias = update_bias
    self._weight_scale = weight_scale
    self._clip_value = clip_value
    self._scope = scope
    self._numContexts = numContexts
    self._contextIdx = contextIdx
    self._input_keep_prob = input_keep_prob
    
    with tf.variable_scope(self._scope):        
        #input and state weight matrices
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

class ContextLSTMCell(tf.nn.rnn_cell.RNNCell):
  """
  LSTM
  Following equations in: https://arxiv.org/abs/1409.2329
  Splitting apart the affine transformation into component weights/biases
  """
  def __init__(self, num_units, num_inputs, scope, contextIdx, numContexts=1,
               input_keep_prob=1.0, reset_bias=1.0, update_bias=-1.0, weight_scale=1.0,
               clip_value=np.inf, collections=None):

    self._num_units = num_units
    self._num_inputs = num_inputs
    self._reset_bias = reset_bias
    self._update_bias = update_bias
    self._weight_scale = weight_scale
    self._clip_value = clip_value
    self._scope = scope
    self._numContexts = numContexts
    self._contextIdx = contextIdx
    self._input_keep_prob = input_keep_prob
    
    with tf.variable_scope(self._scope):
        #input gate
        self.W_i = tf.get_variable("W_i", dtype=tf.float32, 
                initializer=initializeWeights([self._num_inputs, self._num_units ], weight_scale), trainable=True)
           
        self.U_i = tf.get_variable("U_i", dtype=tf.float32, 
                initializer=initializeWeights([self._num_units, self._num_units ], weight_scale), trainable=True)
        
        self.b_i = tf.get_variable("b_i", [1, self._num_units], dtype=tf.float32, 
                initializer=tf.constant_initializer(self._update_bias), trainable=True)
        
        #forget gate
        self.W_f = tf.get_variable("W_f", dtype=tf.float32, 
                initializer=initializeWeights([self._num_inputs, self._num_units ], weight_scale), trainable=True)
        
        self.U_f = tf.get_variable("U_f", dtype=tf.float32, 
                initializer=initializeWeights([self._num_units, self._num_units ], weight_scale), trainable=True)
        
        self.b_f = tf.get_variable("b_f", [1, self._num_units], dtype=tf.float32, 
                initializer=tf.constant_initializer(self._reset_bias), trainable=True)
        
        #output gate
        self.W_o = tf.get_variable("W_o", dtype=tf.float32, 
                initializer=initializeWeights([self._num_inputs, self._num_units], weight_scale), trainable=True)
        
        self.U_o = tf.get_variable("U_o", dtype=tf.float32, 
                initializer=initializeWeights([self._num_units, self._num_units ], weight_scale), trainable=True)
        
        self.b_o = tf.get_variable("b_o", [1, self._num_units], dtype=tf.float32, 
                initializer=tf.zeros_initializer, trainable=True)
        
        #activation 
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
         
    self._weightVariables = [self.W_i, self.U_i, self.W_f, self.U_f, self.W_o, self.U_o, self.W, self.U]
    
  @property
  def state_size(self):
    return self._num_units*2

  @property
  def output_size(self):
    return self._num_units

  def __call__(self, inputs, state, scope=None):

    with tf.variable_scope(self._scope):
      #add dropout to inputs
      tf.nn.dropout(inputs, self._input_keep_prob)
      
      #split state into hidden units and memory cell activation
      c, h = tf.split(value=state, num_or_size_splits=2, axis=1)
      
      with tf.variable_scope("Gates"):  # input, forget, output gates
        i = tf.sigmoid(tf.matmul(inputs, self.W_i) + tf.matmul(h, self.U_i) + self.b_i)
        f = tf.sigmoid(tf.matmul(inputs, self.W_f) + tf.matmul(h, self.U_f) + self.b_f)
        o = tf.sigmoid(tf.matmul(inputs, self.W_o) + tf.matmul(h, self.U_o) + self.b_o)
    
      with tf.variable_scope("UpdateCell"): #cell update
        g = tf.tanh(tf.matmul(inputs, self.W) + tf.matmul(h, self.U) + self.activeContextBias)
        new_c = tf.multiply(f, c) + tf.multiply(i, g)
    
      with tf.variable_scope("StateUpdate"): #state update
          new_h = tf.multiply(o, tf.tanh(new_c))
    
      new_state = tf.concat([new_c, new_h], 1)   
      
    return new_h, new_state