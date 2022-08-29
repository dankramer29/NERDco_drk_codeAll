import numpy as np
import scipy.misc
import matplotlib.pyplot

weights = W_conv1.eval()

# Get each 5x5 filter from the 5x5x1x32 array
for filter_ in range(weights.shape[3]):
    # Get the 5x5x1 filter:
    extracted_filter = weights[:, :, :, 5]

    # Get rid of the last dimension (hence get 5x5):
    extracted_filter = np.squeeze(extracted_filter)

    # display the filter (might be very small - you can resize the window)
    matplotlib.pyplot.gray()
    matplotlib.pyplot.imshow(extracted_filter)
    matplotlib.pyplot.show()