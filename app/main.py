from fastapi import FastAPI
import socket

app = FastAPI()

@app.get("/")
def read_root():
    hostname = socket.gethostname()
    return {
        "message": "Application is running",
        "hostname": hostname
    }

@app.get("/health")
def health_check():
    return {"status": "OK"}
