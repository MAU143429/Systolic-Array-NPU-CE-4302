import numpy as np
import matplotlib.pyplot as plt
from scipy.ndimage import convolve
import cv2

# Load custom grayscale image
image_path = "/home/mau14/Desktop/Arquitectura de Computadores II/Proyecto-2-Arqui-II/Systolic-Array-NPU-CE-4302/Prototype-Testing/cat.jpg"  # replace with your image path
original_image = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)

# Ensure the image is square by cropping to the smallest dimension
height, width = original_image.shape
side = min(height, width)
image = original_image[:side, :side]  # crop to nxn

step_edge_10x10 = np.array([
    [ 1,  2,  3,  4,  5,  5,  4,  3,  2,  1 ],
    [ 2,  4,  6,  8, 10, 10,  8,  6,  4,  2 ],
    [ 3,  6,  9, 12, 15, 15, 12,  9,  6,  3 ],
    [ 4,  8, 12, 16, 20, 20, 16, 12,  8,  4 ],
    [ 5, 10, 15, 20, 25, 25, 20, 15, 10,  5 ],
    [ 5, 10, 15, 20, 25, 25, 20, 15, 10,  5 ],
    [ 4,  8, 12, 16, 20, 20, 16, 12,  8,  4 ],
    [ 3,  6,  9, 12, 15, 15, 12,  9,  6,  3 ],
    [ 2,  4,  6,  8, 10, 10,  8,  6,  4,  2 ],
    [ 1,  2,  3,  4,  5,  5,  4,  3,  2,  1 ]
], dtype=np.int32)

# Aplicar convolución con step_edge_10x10
convolved = convolve(image.astype(np.int32), step_edge_10x10, mode='constant', cval=0)

# Aplicar Leaky ReLU
alpha = 0.1
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
