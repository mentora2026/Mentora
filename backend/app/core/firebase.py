import firebase_admin
from firebase_admin import credentials, messaging
from app.core.config import settings

import json

def initialize_firebase():
    if not firebase_admin._apps:
        try:
            if settings.FIREBASE_CREDENTIALS_JSON:
                json_str = settings.FIREBASE_CREDENTIALS_JSON
                # Render might escape newlines, so we replace literal '\n' with actual newlines if needed
                if "\\n" in json_str and "\n" not in json_str:
                    json_str = json_str.replace("\\n", "\n")
                
                cred_dict = json.loads(json_str)
                cred = credentials.Certificate(cred_dict)
                firebase_admin.initialize_app(cred)
                print("Firebase Admin SDK initialized successfully from JSON string.")
            elif settings.FIREBASE_CREDENTIALS_PATH:
                cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
                firebase_admin.initialize_app(cred)
                print("Firebase Admin SDK initialized successfully from file path.")
            else:
                print("FIREBASE_CREDENTIALS_PATH or JSON not set. Firebase not initialized.")
        except Exception as e:
            print(f"Error initializing Firebase Admin SDK: {e}")

def send_push_notification(token: str, title: str, body: str, data: dict = None):
    if not firebase_admin._apps:
        print("Firebase Admin SDK is not initialized. Cannot send notification.")
        return False

    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data if data else {},
            token=token,
        )
        response = messaging.send(message)
        print(f"Successfully sent message: {response}")
        return True
    except Exception as e:
        print(f"Error sending message: {e}")
        return False
