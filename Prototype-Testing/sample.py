import numpy as np
import matplotlib.pyplot as plt
from scipy.ndimage import convolve
import cv2

# Load custom grayscale image
image_path = "Prototype-Testing/image5.jpg"  # replace with your image path
original_image = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)

# Ensure the image is square by cropping to the smallest dimension
height, width = original_image.shape
side = min(height, width)
image = original_image[:side, :side]  # crop to nxn

step_edge_10x10 = np.array([
    [ 1]*10, 
    [ 1]*10,
    [ 1]*10,
    [ 1]*10,
    [ 1]*10,
    [-1]*10,
    [-1]*10,
    [-1]*10,
    [-1]*10,
    [-1]*10
], dtype=np.int32)

# Aplicar convolución con step_edge_10x10
convolved = convolve(image.astype(np.int32), step_edge_10x10, mode='constant', cval=0)

# Aplicar Leaky ReLU
alpha = 0.13
leaky_relu = np.where(convolved >= 0, convolved, convolved * alpha)

# Normalizar
normalized = leaky_relu - leaky_relu.min()
normalized = (normalized / normalized.max()) * 255
normalized = normalized.astype(np.uint8)

# Mostrar resultados
fig, axs = plt.subplots(1, 2, figsize=(10, 5))
axs[0].imshow(image, cmap='gray')
axs[0].set_title('Imagen Original')
axs[0].axis('off')

axs[1].imshow(normalized, cmap='gray')
axs[1].set_title('Step Edge 10x10 + Leaky ReLU')
axs[1].axis('off')

plt.tight_layout()
plt.show()

