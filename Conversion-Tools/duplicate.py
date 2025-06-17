from PIL import Image
import numpy as np

# Parámetros
img1_path = "Prototype-Testing/cat.jpg"
img2_path = "Prototype-Testing/400.jpg"
mif_path = "dual_image.mif"
WIDTH = 8

# Cargar imágenes como escala de grises y redimensionar a 400x400
img1 = Image.open(img1_path).convert("L").resize((400, 400))
img2 = Image.open(img2_path).convert("L").resize((400, 400))

# Convertir a arrays
arr1 = np.array(img1, dtype=np.uint8).flatten()
arr2 = np.array(img2, dtype=np.uint8).flatten()

# Concatenar las dos imágenes
data = np.concatenate([arr1, arr2])

DEPTH = len(data)

# Crear archivo MIF
with open(mif_path, "w") as f:
    f.write(f"WIDTH={WIDTH};\n")
    f.write(f"DEPTH={DEPTH};\n\n")
    f.write("ADDRESS_RADIX=HEX;\n")
    f.write("DATA_RADIX=HEX;\n\n")
    f.write("CONTENT BEGIN\n")

    for i in range(DEPTH):
        f.write(f"  {i:X} : {data[i]:02X};\n")

    f.write("END;\n")
