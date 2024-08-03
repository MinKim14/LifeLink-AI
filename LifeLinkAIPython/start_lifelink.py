from firebase_data_monitor import FirebaseDataHandler

data_handler = FirebaseDataHandler()
try:
    data_handler.start_monitoring()
except KeyboardInterrupt:
    print("Shutting down gracefully...")