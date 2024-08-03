import os
import pickle
import time
import uuid
import torch
import torch.nn.functional as F
from datetime import datetime
DATA_DIR = 'user_data'
os.makedirs(DATA_DIR, exist_ok=True)

def is_time_difference_less_than_one_hour(t1, t2):
    # Convert timestamps to datetime objects
    dt1 = datetime.fromtimestamp(t1)
    dt2 = datetime.fromtimestamp(t2)
    
    # Extract time components only (ignore date)
    time1 = dt1.time()
    time2 = dt2.time()
    
    # Calculate the difference in seconds
    delta = abs((datetime.combine(datetime.min, time1) - datetime.combine(datetime.min, time2)).total_seconds())
    
    # Check if the difference is less than 3600 seconds (1 hour)
    return delta < 3600

def get_file_path(user_id, data_type):
    return os.path.join(DATA_DIR, f"{data_type}_{user_id}.pkl")

def load_data(user_id, data_type):
    file_path = get_file_path(user_id, data_type)
    if(not os.path.exists(file_path)):
        initialize_user(user_id)

    with open(file_path, 'rb') as f:
        return pickle.load(f)

def save_data(user_id, data_type, data):
    file_path = get_file_path(user_id, data_type)
    with open(file_path, 'wb') as f:
        pickle.dump(data, f)

def initialize_user(user_id=None):
    user_id = user_id if user_id else str(uuid.uuid4())
    paired_file_path = get_file_path(user_id, 'paired_data')
    last_state_file_path = get_file_path(user_id, 'last_state')
    chat_history_file_path = get_file_path(user_id, 'chat_history')

    if(os.path.exists(paired_file_path) and os.path.exists(last_state_file_path) and os.path.exists(chat_history_file_path)):
        return

    paired_data = []
    last_state = {
        'last_embedding': None,
        'last_time': None,
        'last_paired_embedding': None,
        'last_paired_time': None,
        'last_paired_action': None,
        'last_paired_meta_info': None,
        'last_paired_summary': None
    }

    save_data(user_id, 'paired_data', paired_data)
    save_data(user_id, 'last_state', last_state)
    save_data(user_id, 'chat_history', None)
    return user_id

def add_or_update_paired_data(user_id, action, meta_info, summary):
    paired_data = load_data(user_id, 'paired_data')
    last_state = load_data(user_id, 'last_state')

    embedding = last_state['last_embedding']
    if(embedding is None):
        return
    last_state.update({
        'last_paired_embedding': embedding,
        'last_paired_time': time.time(),
        'last_paired_action': action,
        'last_paired_meta_info': meta_info,
        'last_paired_summary': summary
    })
    paired_data.append({
        'embedding': embedding,
        'action': action,
        'meta_info': meta_info,
        'summary': summary,
        'time': time.time()
    })
    save_data(user_id, 'paired_data', paired_data)
    save_data(user_id, 'last_state', last_state)

def save_chat_history(user_id, history):
    chat_history = {
        'history': history,
        'time': time.time()
    }
    save_data(user_id, 'chat_history', chat_history)

def load_chat_history(user_id):
    return load_data(user_id, 'chat_history')

def update_last_embedding(user_id, embedding, current_time):
    last_state = load_data(user_id, 'last_state')
    last_state.update({
        'last_embedding': embedding,
        'last_time': current_time
    })
    save_data(user_id, 'last_state', last_state)

def compare_embedding(user_id, new_embedding, current_time):
    last_state = load_data(user_id, 'last_state')
    paired_data = load_data(user_id, 'paired_data')

    last_paired_embedding = last_state['last_paired_embedding']
    last_paired_time = last_state['last_paired_time']
    last_paired_action = last_state['last_paired_action']
    last_paired_meta_info = last_state['last_paired_meta_info']
    last_paired_summary = last_state['last_paired_summary']
    last_embedding = last_state['last_embedding']
    last_time = last_state['last_time']

    response = {
        "action_required": False,
        "action": None,
        "meta_info": None,
        "summary": None
    }
    update_last_embedding(user_id, new_embedding, current_time)

    if last_paired_embedding is not None and (current_time - last_paired_time) <= 1200:
        similarity = F.cosine_similarity(last_paired_embedding, new_embedding, dim=0).item()
        if similarity > 0.2:
            response["action_required"] = False
            response["action"] = last_paired_action
            response["meta_info"] = last_paired_meta_info
            response["summary"] = last_paired_summary
        
            return response
        elif similarity > 0.1:
            response["action_required"] = True
            response["action"] = last_paired_action
            response["meta_info"] = last_paired_meta_info
            response["summary"] = last_paired_summary
            return response
        
    elif last_paired_embedding is not None and (current_time - last_paired_time) <= 2400:
        similarity = F.cosine_similarity(last_paired_embedding, new_embedding, dim=0).item()
        if similarity > 0.3:
            response["action_required"] = False
            response["action"] = last_paired_action
            response["meta_info"] = last_paired_meta_info
            response["summary"] = last_paired_summary
            return response
        elif similarity > 0.2:
            response["action_required"] = True
            response["action"] = last_paired_action
            response["meta_info"] = last_paired_meta_info
            response["summary"] = last_paired_summary
            return response

    if last_embedding is not None and (current_time - last_time) <= 1200:
        similarity = F.cosine_similarity(last_embedding, new_embedding, dim=0).item()
        if similarity > 0.4:
            return response

    if paired_data:
        embeddings = torch.stack([entry['embedding'] for entry in paired_data])
        similarities = F.cosine_similarity(embeddings, new_embedding.unsqueeze(0), dim=1)
        best_similarity, best_index = torch.max(similarities, dim=0)

        if best_similarity.item() > 0.7:
            best_match = paired_data[best_index]
            if is_time_difference_less_than_one_hour(current_time, best_match['time']):
                response["action_required"] = False
            else:
                response["action_required"] = True
            response["action"] = best_match['action']
            response["meta_info"] = best_match['meta_info']
            response["summary"] = best_match['summary']
            return response
    
    # No match found
    response["action_required"] = True
    return response