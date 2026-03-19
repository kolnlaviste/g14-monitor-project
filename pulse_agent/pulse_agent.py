import psutil
import time
import os
from supabase import create_client, Client

URL = "https://tvfpzoutoowujxpilqeo.supabase.co"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2ZnB6b3V0b293dWp4cGlscWVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4OTIwNzcsImV4cCI6MjA4NDQ2ODA3N30.Va9InJHhMzfEmkORMi2M1i0Q4qcSJ-2TY2BUVwCih0o"
supabase: Client = create_client(URL, KEY)

def get_system_usage():
    cpu_usage = psutil.cpu_percent(interval=1)
    ram_usage = psutil.virtual_memory().percent

    battery = psutil.sensors_battery()
    if battery:
        bat_percent = battery.percent
        is_plugged = battery.power_plugged
    else: 
        bat_percent = 0
        is_plugged = True

    return {
        "cpu_usage": cpu_usage,
        "ram_usage": ram_usage,
        "battery_level": bat_percent,
        "is_plugged": is_plugged
    }

print("Starting Pulse Agent...")

while True:
    try:
        stats = get_system_usage()
        data, count = supabase.table("system_stats").insert(stats).execute()

        print(f"Successfully Pushed: CPU {stats['cpu_usage']}% | RAM {stats['ram_usage']}%")
    except Exception as e:
        print(f"Error pushing data: {e}")

    
    time.sleep(10)