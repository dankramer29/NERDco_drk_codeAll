%controller network
nCursorDim = 2;
nControllerUnits = 20;

trainIn = randn(10000,4)';
trainOut = trainIn(1:2,:);

net = feedforwardnet(nControllerUnits);
net = train(net, trainIn, trainOut);

    W_control_in = tf.get_variable("W_ftarg_in", dtype=tf.float32, 
                    initializer=initializeWeights([nControllerUnits, nCursorDim*2 ], 1.0), trainable=True)
    b_control_in = tf.get_variable("b_ftarg_in", dtype=tf.float32, 
                    initializer=initializeWeights([nControllerUnits, 1 ], 1.0), trainable=True)
    W_control_out = tf.get_variable("W_ftarg_out", dtype=tf.float32, 
                    initializer=initializeWeights([nCursorDim, nControllerUnits ], 1.0), trainable=True)
    b_control_out = tf.get_variable("b_ftarg_out", dtype=tf.float32, 
                    initializer=initializeWeights([nCursorDim, 1 ], 1.0), trainable=True)