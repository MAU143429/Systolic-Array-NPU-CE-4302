from PIL import Image
import numpy as np

# Parámetros
img_path = "Prototype-Testing/cat.jpg"
mif_path = "cat.mif"
WIDTH = 8

# Cargar imagen como escala de grises
img = Image.open(img_path).convert("L")
arr = np.array(img, dtype=np.uint8)

# Verificar dimensiones
height, width = arr.shape
DEPTH = height * width

# Guardar como RAW si es necesario
arr.tofile("img.raw")

# Aplanar datos
data = arr.flatten()

# Limitar la longitud del array por si se corrompe el tamaño
data = data[:DEPTH]

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
