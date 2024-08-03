import json
import threading
from datetime import datetime, timedelta
import numpy as np
import uuid
import time
from user_model_manager import *
from firebase_admin import credentials, db

class FirebaseHandler:
    def __init__(self, gemini_model):
        self.gemini_model = gemini_model
        self.db_parent_ref = db.reference('')
        self.db_listener_thread = threading.Thread(target = self.listen_for_db_changes)
        self.db_listener_thread.daemon = True
        self.db_listener_thread.start()

        self.sleep_info = None
        self.start = True
        self.handle_id = None

    def listen_for_db_changes(self):
        def db_event_handler(event):
            if(len(event.path.split("/")) < 3):
                return
            user_id = event.path.split("/")[1]
            event_dir = event.path.split("/")[2]
            if event_dir == "question":
                text, text_time = event.data["text"], event.data["timestamp"]
                self.handle_question_change(user_id, text, text_time)
            elif event_dir == "response":
                text, text_time = event.data["text"], event.data["timestamp"]
                self.handle_user_response(user_id, text, text_time)
            # else:
            #     print("No event handler for path: ", event_dir, "in user: ", user_id)
        self.db_parent_ref.listen(db_event_handler)

    def handle_user_response(self, user_id, text, text_time):
        current_time = time.time()
        ten_minutes_in_seconds = 10 * 60
        
        if current_time - text_time > ten_minutes_in_seconds:
            return
        date = datetime.now().strftime('%Y-%m-%d')
        unique_key = str(uuid.uuid4())
        new_chat = {
            "id": unique_key,
            "text": text,
            "sender": 'user',
            "timestamp": datetime.now().isoformat()
        }
        self.db_parent_ref.child(user_id).child("chats").child(date).push(new_chat)
        previous_chat_history = load_chat_history(user_id)
        if(previous_chat_history is not None and time.time() - previous_chat_history["time"] < 10 * 60):
            motion_info, question, case_id  = self.gemini_model.send_reply(text, previous_chat_history)
        else:
            motion_info, question, case_id  = self.gemini_model.send_reply(text)

        action, meta_info, summary = motion_info

        self.fix_action_history(user_id, action, summary, meta_info)
        add_or_update_paired_data(user_id, action, meta_info, summary)

        if(case_id != 2):
            self.update_model_message(user_id, question)
        else:
            self.update_model_message(user_id, "Clear, " + summary)
    

    def handle_question_change(self, user_id, text, text_time):
        current_time = time.time()
        ten_minutes_in_seconds = 10 * 60
        
        if current_time - text_time > ten_minutes_in_seconds:
            return

        date = datetime.now().strftime('%Y-%m-%d')
        unique_key = str(uuid.uuid4())
        new_chat = {
            "id": unique_key,
            "text": text,
            "sender": 'user',
            "timestamp": datetime.now().isoformat()
        }
        self.db_parent_ref.child(user_id).child("chats").child(date).push(new_chat) 

        model_answer, case_idx = self.gemini_model.simple_answering(text)
        if(case_idx != 2):
            self.db_parent_ref.child(user_id).child("model_answer").set(model_answer)
            date = datetime.now().strftime('%Y-%m-%d')
            unique_key = str(uuid.uuid4())
            model_answer = model_answer.replace("\n","")
            new_chat = {
                "id": unique_key,
                "text": model_answer,
                "sender": 'model',
                "timestamp": datetime.now().isoformat()
            }
            self.db_parent_ref.child(user_id).child("chats").child(date).push(new_chat)

            if(case_idx == 1):
                self.trigger_sleep()

    def update_daily_summary(self, user_id):
        histories = self.get_all_history(user_id, datetime.now().strftime('%Y-%m-%d'))
        if(histories is None):
            return
        total_day = {}
        for history in histories:
            key = history.get("startTime") + "-" + history.get("endTime")
            total_day[key] = history.get("summary")

        new_daily_summary = self.gemini_model.generate_daily_summary(total_day, datetime.now().strftime('%Y-%m-%d'))
        path = f"{user_id}/overview/{datetime.now().strftime('%Y-%m-%d')}"
        ref = db.reference(path)
        ref.set(new_daily_summary)

    def trigger_sleep(self, user_id):
        start_time = time.time()
        end_time = start_time + 60
        start_dt = datetime.fromtimestamp(start_time)
        end_dt = datetime.fromtimestamp(end_time)
        unique_key = str(uuid.uuid4())

        new_summary = {
            "id": unique_key,
            "startTime": start_dt.strftime('%H:%M'),
            "endTime": end_dt.strftime('%H:%M'),
            "actionKeyword": "sleeping",
            "metaData": "sleeping",
            "summary": "sleeping"
        }
        date = datetime.now().strftime('%Y-%m-%d')
        self.db_parent_ref.child(user_id).child("summaries").child(date).push(new_summary)
        self.db_parent_ref.child(user_id).child("need_to_visualize").child(date).set("true")


    # Function to get the last and second-to-last summaries
    def get_last_two_summaries(self, user_id, date):
        path = f"{user_id}/summaries/{date}"
        ref = db.reference(path)
        data = ref.get()
        if not data:
            return None, None
        # Sort the summaries by keys (summary_id) to ensure chronological order
        sorted_summaries = sorted(data.items(), key=lambda item: item[0])
        # Get the last and second-to-last summaries
        if len(sorted_summaries) >= 2:
            second_last_summary = sorted_summaries[-2]
            last_summary = sorted_summaries[-1]
        elif len(sorted_summaries) == 1:
            second_last_summary = None
            last_summary = sorted_summaries[-1]
        else:
            second_last_summary = None
            last_summary = None

        return second_last_summary, last_summary
    
    def add_action_history(self, user_id, action, description, meta_info, start_time=None, end_time=None):
        if start_time is None:
            start_time = time.time()
        if end_time is None:
            end_time = start_time + 60
        current_time = datetime.now().time()
        start_dt = datetime.fromtimestamp(start_time)
        end_dt = datetime.fromtimestamp(end_time)
        unique_key = str(uuid.uuid4())
        date = datetime.now().strftime('%Y-%m-%d')
        second_last_summary, last_summary = self.get_last_two_summaries(user_id, date)
        if last_summary:
            last_summary_id, last_summary_data = last_summary
            last_end_time = datetime.strptime(last_summary_data['endTime'], '%H:%M')
            if timedelta(hours=current_time.hour, minutes=current_time.minute) - timedelta(hours=last_end_time.hour, minutes=last_end_time.minute) < timedelta(minutes=30):
                if(self.gemini_model.check_action_similarity(last_summary_data["actionKeyword"], action)):
                    ref = db.reference(f"{user_id}/summaries/{date}/{last_summary_id}")
                    ref.update({'endTime': end_dt.strftime('%H:%M')})
                    self.update_daily_summary(user_id)
                    return

        # otherwise, add a new action
        action = self.convert_action_name(user_id, action)
        new_summary = {
            "id": unique_key,
            "startTime": start_dt.strftime('%H:%M'),
            "endTime": end_dt.strftime('%H:%M'),
            "actionKeyword": action,
            "metaData": meta_info,
            "summary": description
        }
        self.db_parent_ref.child(user_id).child("summaries").child(date).push(new_summary)
        self.update_daily_summary(user_id)
        return unique_key
    
    def get_all_history(self, user_id, date):
        path = f"{user_id}/summaries/{date}"
        ref = db.reference(path)
        summaries = ref.get()
        # summaries = self.db.child(user_id).child("summaries").child(date).get()
        if(summaries is None):
            return None 
        all_history = []
        for summary_id in summaries:
            summary_data = summaries[summary_id]
            all_history.append(summary_data)
        return all_history
    
    def convert_action_name(self, user_id, action):
        date = datetime.now().strftime('%Y-%m-%d')
        path = f"{user_id}/summaries/{date}"
        ref = db.reference(path)
        summaries = ref.get()
        # summaries = self.db.child(user_id).child("summaries").child(date).get()
        if(summaries is None):
            return action 
        for summary_id in summaries:
            summary_action = summaries[summary_id]["actionKeyword"]
            if(self.gemini_model.check_action_similarity(summary_action, action)):
                return summary_action
        return action            

    def fix_action_history(self, user_id, action, description, meta_info):
        date = datetime.now().strftime('%Y-%m-%d')
        current_time = datetime.now().time()

        # Get the last and second-to-last summaries for the given user_id and date
        second_last_summary, last_summary = self.get_last_two_summaries(user_id, date)
        # Print the retrieved summaries
        if last_summary:
            last_summary_id, last_summary_data = last_summary
            last_start_time = datetime.strptime(last_summary_data['startTime'], '%H:%M')
            last_end_time = datetime.strptime(last_summary_data['endTime'], '%H:%M')
            if timedelta(hours=current_time.hour, minutes=current_time.minute) - timedelta(hours=last_start_time.hour, minutes=last_start_time.minute) < timedelta(minutes=20):
                if second_last_summary:
                    second_last_summary_id, second_last_summary_data = second_last_summary
                    second_last_end_time = datetime.strptime(second_last_summary_data['endTime'], '%H:%M')

                    if last_start_time - second_last_end_time < timedelta(minutes=30):
                        # Update the endTime of the second-last summary
                        if(self.gemini_model.check_action_similarity(second_last_summary_data["actionKeyword"], action)):
                            ref = db.reference(f"{user_id}/summaries/{date}/{second_last_summary_id}")
                            ref.update({'endTime': last_summary_data['endTime'], 'summary': description, 'metaData': meta_info})
                            ref = db.reference(f"{user_id}/summaries/{date}/{last_summary_id}")
                            ref.delete()
                            self.update_daily_summary(user_id)
                            return
                
                ref = db.reference(f"{user_id}/summaries/{date}/{last_summary_id}")
                ref.update({'actionKeyword': action, 'metaData': meta_info, 'summary': description})
                self.update_daily_summary(user_id)
                return
        else:
            # Add a new action history
            self.add_action_history(user_id, action, description, meta_info)
            self.update_daily_summary(user_id)
            return

    def elong_last_history(self, user_id, end_time):
        end_dt = datetime.fromtimestamp(end_time)
        date = datetime.now().strftime('%Y-%m-%d')
        current_time = datetime.now().time()
        second_last_summary, last_summary = self.get_last_two_summaries(user_id, date)
        if last_summary:
            last_summary_id, last_summary_data = last_summary
            last_end_time = datetime.strptime(last_summary_data['endTime'], '%H:%M')
            if timedelta(hours=current_time.hour, minutes=current_time.minute) - timedelta(hours=last_end_time.hour, minutes=last_end_time.minute) < timedelta(minutes=30):
                ref = db.reference(f"{user_id}/summaries/{date}/{last_summary_id}")
                ref.update({'endTime': end_dt.strftime('%H:%M')})
                self.update_daily_summary(user_id)
                return True
                
        return False

    def update_model_message(self, user_id, new_message):#, cur_emb = None):
        self.db_parent_ref.child(user_id).child("model_message").set(new_message)
        date = datetime.now().strftime('%Y-%m-%d')
        unique_key = str(uuid.uuid4())
        new_message = new_message.replace("\n","")
        new_chat = {
            "id": unique_key,
            "text": new_message,
            "sender": 'model',
            "timestamp": datetime.now().isoformat()
        }
        self.db_parent_ref.child(user_id).child("chats").child(date).push(new_chat)

    def add_greeting(self, user_id, greeting):
        date = datetime.now().strftime('%Y-%m-%d')
        path = f"{user_id}/chats/{date}"
        ref = db.reference(path)
        chats = ref.get()
        if(chats):
            return
        else:
            self.update_model_message(user_id, greeting)


