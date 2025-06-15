from PIL import Image
import numpy as np

# Cargar imagen, convertir a escala de grises
img = Image.open("Prototype-Testing/cat.jpg").convert("L")
arr = np.array(img, dtype=np.uint8)

# Guardar como archivo binario plano (raw)
arr.tofile("cat.raw")

# Generar MIF
mif_path = "cat.mif"
data = arr.flatten()

DEPTH = 15728640  # 15 MB
WIDTH = 8

with open(mif_path, "w") as f:
    f.write(f"WIDTH={WIDTH};\n")
    f.write(f"DEPTH={DEPTH};\n\n")
    f.write("ADDRESS_RADIX=HEX;\n")
    f.write("DATA_RADIX=HEX;\n\n")
    f.write("CONTENT BEGIN\n")

    for i in range(DEPTH):
        val = data[i] if i < len(data) else 0  # rellenar con ceros si sobra espacio
        f.write(f"  {i:X} : {val:02X};\n")

    f.write("END;\n")
