import socket
import time
import sys
 
host = 'localhost'
port = 2540
size = 1024
 
def open_server(host, port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((host, port))
    return s
 
def sed_data_to_fpga(conn, intValue):
    size = 8
    bStr_LEDValue = bin(intValue).split('0b')[1].zfill(size) #Convert from int to binary string
    request = bStr_LEDValue + '\n' #'\n' is required to flush buffer on TCL server
    conn.send(request.encode())
 
conn = open_server(host, port)

for i in range(1024):
    sed_data_to_fpga(conn, i%255)
# while True:
#     data = input("Please enter number 0-255 or type 'Exit' to exit:\n")
#     assert((data == "Exit") or (0 <= int(data) <= 255)) 
#     if 'Exit' == data:
#         break
#     print(f'|INFO| processing user input = {data}')
#     data = int(data)
#     sed_data_to_fpga(conn, data)

print("Done")
 
conn.close()