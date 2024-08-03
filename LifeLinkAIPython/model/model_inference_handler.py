import time
from user_model_manager import save_chat_history

class ModelInferenceHandler:
    def __init__(self, inference_model, firebase_handler, gemini_model):
        self.inference_model = inference_model
        self.firebase_handler = firebase_handler
        self.gemini_model = gemini_model
        self.prev_time = time.time()

    def run(self, user_id, acc, ori):
        inference_result = self.inference_model.run_inference(user_id, acc, ori)
        motion_description = inference_result["motion_description"]
        joint = inference_result["full_joint"]
        cur_emb = inference_result["total_emb"]
        additional_info = inference_result["additional_info"]
        action = additional_info["action"]
        meta_info = additional_info["meta_info"]
        summary = additional_info["summary"]

        if motion_description is None:
            # no need to send message to user (action not required)
            if action is not None:
                self.firebase_handler.add_action_history(user_id, action, summary, meta_info, time.time())
                # print("Add history same as last paired")
            else:
                self.firebase_handler.elong_last_history(user_id, time.time())
                # print("No motion description no need to ask")
        else:
            # need to send message to user (action required)
            motion_info, model_question, case_num, gemini_chat_history = self.gemini_model.recognize_activity(motion_description)
            save_chat_history(user_id, gemini_chat_history)
            action, meta_info, summary = motion_info
            self.firebase_handler.add_action_history(user_id, action, summary, meta_info, time.time())

            # if case_num != 2 or joint is not None:
            if case_num != 2:
                self.firebase_handler.update_model_message(user_id, model_question)