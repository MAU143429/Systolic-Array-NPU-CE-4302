import numpy as np
from PIL import Image

# Definir la matriz A (valores de 0 a 180, como en tu imagen)
A = np.array([
    [0, 10, 20, 30, 40, 50, 60, 70, 80, 90],
    [10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
    [20, 30, 40, 50, 60, 70, 80, 90, 100, 110],
    [30, 40, 50, 60, 70, 80, 90, 100, 110, 120],
    [40, 50, 60, 70, 80, 90, 100, 110, 120, 130],
    [50, 60, 70, 80, 90, 100, 110, 120, 130, 140],
    [60, 70, 80, 90, 100, 110, 120, 130, 140, 150],
    [70, 80, 90, 100, 110, 120, 130, 140, 150, 160],
    [80, 90, 100, 110, 120, 130, 140, 150, 160, 170],
    [90, 100, 110, 120, 130, 140, 150, 160, 170, 180]
], dtype=np.uint8)

# Crear imagen en escala de grises ('L' = 8-bit pixels, black and white)
img = Image.fromarray(A, mode='L')

# Guardar como imagen PNG
img.save("matriz_10x10_grises.png")
print("Imagen guardada como matriz_10x10_grises.png")
