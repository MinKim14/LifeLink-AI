import torch
import yaml
from model.vmGpt.vague_motion_mgpt import VagueMotionGPT
from model.m2t_utils import *

model = VagueMotionGPT()
state_dict = torch.load("model_log/VagueMotionGPT.pt", map_location="cpu")
model.load_state_dict(state_dict)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

def get_motion_description(joint, trans):
    # joint: bs, ws, 24, 3, trans: bs, ws, 3
    cur_joint = joint + trans.unsqueeze(2) 
    cur_joint = cur_joint[0][:, :joints_num]
    cur_joint = cur_joint.cpu().detach().numpy()
    cur_data, ground_positions, positions, l_velocity = process_file(cur_joint, 0.002)
    norm_cur_data = (cur_data - mean) / std
    feats = torch.tensor(norm_cur_data).to(device).float()
    cur_feats = feats.unsqueeze(0)
    motion_token, _ = model.vae.encode(cur_feats)
    motion_token_string = model.lm.motion_token_to_string(
        motion_token, [motion_token.shape[1]]
    )[0]
    
    window_size = norm_cur_data.shape[0]
    input = "Describe the motions in <Motion_Placeholder> in natural language."
    prompt = model.lm.placeholder_fulfill(input, window_size, motion_token_string, "")
    batch = {
        "length": [1],
        "text": [prompt],
    }

    outputs = model(batch, task="t2m")
    return outputs["texts"]
