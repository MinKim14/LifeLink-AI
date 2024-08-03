import time
from datetime import datetime

import google.generativeai as genai

class GeminiCommunicator:
    def __init__(self, api_key):
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel("gemini-1.5-flash")
        self.chat = self.model.start_chat()

    def generate_greeting(self):
        chat = self.model.start_chat()
        current_time_str = datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')
        response = chat.send_message(
            f"Given that the current time is {current_time_str}, generate a greeting message for me"
        )

        return response.text
    
    def check_good_night(self, message):
        chat = self.model.start_chat()
        response = chat.send_message(
            f"Check if the message '{message}' is a good night message or mentioning he or she is going to sleep, answer in yes or no"
        )

        if "yes" in response.text.lower():
            return True
        else:
            return False
    
    def simple_answering(self, question):
        chat = self.model.start_chat()
        try:
            response = chat.send_message(question +", answer in very simple sentence")
            if(self.check_good_night(response.text)):
                return response.text, 1
            return response.text, 0
        except:
            return "",2    

    def generate_daily_summary(self, summaries, date):
        try:
            message = f"Please provide a total summary of the {date} based on the following summaries:\n"
            for time_range, summary in summaries.items():
                message += f"{time_range}: summary: {summary}\n"

            response = self.chat.send_message(message)
            return response.text
        except:
            return ""

    def check_action_similarity(self, action1, action2):
        response = self.chat.send_message(f"Check if action: {action1} and {action2} are in the similar category, if so, just say yes, if not, just say no")

        if("yes" in response.text or "Yes" in response.text):
            return True
        else:
            return False

    def recognize_activity(self, vague_actions, history = None):
        # Combine actions into a single message
        if(history is not None):
            self.chat = self.model.start_chat()
        else:
            self.chat = self.model.start_chat(history=history)

        if(history is not None):
            message ="Actually, I am doing: " + "".join(vague_actions)
        else:
            message = "I am doing: " + ", and then ".join(vague_actions)

        message = f"Extract what daily activity does the motion description represent. The goal is to determine the daily activity that the motion description represents, such as 'walking', 'working', 'sitting', 'resting', 'exercising', or 'sleeping'. If you can determine which activity I am doing, ask for more information about the activity like destination. If you cannot determine the activity, then ask for it. Response should be a format &simple motion summary : &simple question.  Input: {message}"
        try:
            response = self.chat.send_message(
                message
            )

            response = self.chat.send_message(
                f"Extract what is the action and meta information about the {response.text}, in format: $Action: $Meta_info, if action or meta_info is unclear, replace it with ???"
            )

            action_response = self.chat.send_message(
                f"What is the action in {response.text}, just the action, if action is unclear, say ???"
            )
            meta_response = self.chat.send_message(
                f"What is the meta information in {response.text}, just the meta information, if meta information is unclear, say ???"
            )
            summary_response = self.chat.send_message(
                f"summarize what I am doing in {response.text} for a single sentence"
            )

            if("???" in action_response.text):
                # first just save and ask action again
                response = self.chat.send_message(
                    "Ask what i am doing again"
                )
                return [action_response.text, meta_response.text, summary_response.text], response.text, 0, self.chat.history

            elif("???" in meta_response.text):
                # first just save and ask meta information again
                response = self.chat.send_message(
                    f"With the action {action_response.text}, ask what is the meta information"
                )
                return [action_response.text, meta_response.text, summary_response.text], response.text, 1, self.chat.history
            else:
                # save the action meta information, and summary
                response = self.chat.send_message(
                    f"With the action {action_response.text}, ask whether I am actually doing this action"
                )
                print("very clear, save the action, meta information, and summary")
                return [action_response.text, meta_response.text, summary_response.text], response.text, 2, self.chat.history
        except:
            response = self.chat.send_message(
                "I am doing something"
            )
            action_response = self.chat.send_message(
                f"What is the action in {response.text}, just the action, if action is unclear, say ???"
            )
            meta_response = self.chat.send_message(
                f"What is the meta information in {response.text}, just the meta information, if meta information is unclear, say ???"
            )
            summary_response = self.chat.send_message(
                f"summarize what I am doing in {response.text} for a single sentence"
            )
            return [action_response.text, meta_response.text, summary_response.text], response.text, 0, self.chat.history

    def send_reply(self, reply, history=None):
        if(history is not None):
            motion_info, question, case_id, chat_history = self.recognize_activity([reply], history=history['history'])
        else:
            motion_info, question, case_id, chat_history = self.recognize_activity([reply])

        return motion_info, question, case_id



