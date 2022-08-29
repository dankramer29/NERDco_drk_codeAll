

#delayed feedback -> state estimator -> controller -> noisy channel -> decoder -> noisy feedback channl
#brain -> noisy, magnitude limited channel -> decoder -> noisy feedback channel -> delay

#dynamics simulations
#rhythmic 1D movement
#one shot up -> down movement

#parameterize f_targ and f_vel with feedforward network layers (need separate routine to initialize?)
#approximate forward model with a recurrent neural network (need separate routine to initialize?)
#train forward model with its own cost function that just tries to estimate position and velocity accurately
#add an integrator by default to the end of the decoder, so it doesn't have to learn integration?


import tensorflow as tf
import numpy as np
import scipy.io
import matplotlib.pyplot as plt

nNeurons = 192
nDecFactors = 10
nDecUnits = 50
nForwardModelUnits = 20
nDim = 2
nSteps = 50*10
dt = 0.02
delaySteps = 10
batchSize = 16

#Load neural model from MATLAB file
dataDir = '/Users/frankwillett/Data/Derived/hfDataTmp'
neuralModel = scipy.io.loadmat(dataDir + '/rnnData')
neuralCovariance = neuralModel['neuralCovariance'].astype(np.float32)
neuralTuning = neuralModel['neuralTuning'].astype(np.float32)

#Start tensorflow
sess = tf.InteractiveSession()

#these placeholders must be configured for each new batch
startDecState = tf.placeholder(tf.float32, shape=[nDecUnits, batchSize])
startFMState = tf.placeholder(tf.float32, shape=[nForwardModelUnits, batchSize])
targSeq = tf.placeholder(tf.float32, shape=[nSteps, nDim, batchSize])

#unfold RNNs + control policy in time
decStates = [startDecState]
fmStates = [startFMState]
controlOut = []
for i in range(nSteps):
    feedbackStateIdx = i - delaySteps
    if feedbackStateIdx < 0:
        feedbackStateIdx = 0
        
    z_t = tf.sigmoid(tf.matmul(gru_Wz, neurons[i]) + tf.matmul(gru_Uz, gruStates[i]) + gru_Bz)
    r_t = tf.sigmoid(tf.matmul(gru_Wr, neurons[i]) + tf.matmul(gru_Ur, gruStates[i]) + gru_Br)
    tanhInput = tf.matmul(gru_Wh, neurons[i]) + tf.matmul(gru_Uh, tf.mul(r_t, gruStates[i]) + gru_Bh)
    h_t = tf.mul(z_t, gruStates[i]) + tf.mul(1-z_t, tf.tanh(tanhInput))
    gruStates.append(h_t)
    
    netStates.append(netStates[i]*0.60 + 0.40*tf.tanh(biases + tf.matmul(W, netStates[i]) + tf.matmul(Iseq, inSeq[:,i,:]) + tf.matmul(I, sysStates[feedbackStateIdx])))
    controlOut.append(tf.matmul(U, netStates[i]))
    sysStates.append(tf.matmul(A, sysStates[i]) + tf.matmul(B, controlOut[-1]))
    tf.add_to_collection('PosErr',tf.square(sysStates[-1][0:2]-targSeq[:,i,:]))

totalErr = tf.reduce_sum(tf.add_n(tf.get_collection('PosErr'), name='total_err'))

learnRate = tf.Variable(1.0, trainable=False)
tvars = tf.trainable_variables()
grads, _ = tf.clip_by_global_norm(tf.gradients(totalErr, tvars), 1)
optimizer = tf.train.GradientDescentOptimizer(learnRate)
train_op = optimizer.apply_gradients(zip(grads, tvars),
    global_step=tf.contrib.framework.get_or_create_global_step())
new_lr = tf.placeholder(tf.float32, shape=[], name="new_learning_rate")
lr_update = tf.assign(learnRate, new_lr)

sess.run(tf.global_variables_initializer())
initNet = numpy.zeros([nUnits, 1]) 
trainSteps = 5000

for i in range(trainSteps):
    #learn rate
    lr = 1 - i/trainSteps
    
    #random start state and target
    initSys = numpy.random.normal(0,1,[4,1])
    randTarg = numpy.random.normal(0,1,[2,1])
    randTargSeq = numpy.reshape(numpy.tile(randTarg, [1,nSteps]),[2,nSteps,1])
    
    #descend gradient
    ao, to, te = sess.run([lr_update, train_op, totalErr], feed_dict={new_lr: lr, startNetState: initNet, startSysState: initSys, inSeq: randTargSeq, targSeq: randTargSeq})

    if i%10 == 0:
        print("step %d, training accuracy %g"%(i, te))

#plot trajectory        
randTarg = numpy.random.normal(0,1,[2,1])
randTargSeq = numpy.reshape(numpy.tile(randTarg, [1,nSteps]),[2,nSteps,1])
    
sysTraj, controlTraj, netTraj = sess.run([sysStates, controlOut, netStates], feed_dict={new_lr: lr, startNetState: initNet, startSysState: initSys, inSeq: randTargSeq, targSeq: randTargSeq})
sysTraj = numpy.hstack(sysTraj)
controlTraj = numpy.hstack(controlTraj)
netTraj = numpy.hstack(netTraj)

plt.plot(sysTraj[0,:], sysTraj[1,:])
plt.plot(randTarg[0],randTarg[1], 'o')
plt.ylabel('some numbers')
plt.show()

plt.plot(sysTraj.transpose())
plt.show()

plt.plot(controlTraj.transpose())
plt.show()

plt.plot(netTraj.transpose())
plt.show()

fWriter = tf.summary.FileWriter('C:/Users/Frank/Documents/PythonScripts/linSys/tboard/', sess.graph)

