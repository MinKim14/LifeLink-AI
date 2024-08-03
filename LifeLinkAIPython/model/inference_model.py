import torch
from model.imu_encoder import LeftIMUEncoder
from model.watch_poser import WatchPoser
from model.m2t import get_motion_description
from user_model_manager import *

class InferenceModel:
    def __init__(self, inference_model_config):
        self.watch_poser = WatchPoser(inference_model_config["watch_poser"])
        self.watch_poser = self.watch_poser.to(inference_model_config["device"])
    
        self.imu_encoder = LeftIMUEncoder(inference_model_config["left_imu_encoder"])
        self.imu_encoder = self.imu_encoder.to(inference_model_config["device"])
        self.device = inference_model_config["device"]

    def run_inference(self, user_id, acc, ori):
        with torch.no_grad():
            acc = acc.float().to(self.device)
            ori = ori.float().to(self.device)
            input = torch.cat([acc, ori], dim=-1).unsqueeze(0)
            total_emb = []
            if input.shape[1] > 500:
                for i in range(0, input.shape[1], 500):
                    emb = self.imu_encoder.forward(input[:, i : i + 500])
                    total_emb.append(emb[:, -1])
            else:
                total_emb = [self.imu_encoder.forward(input)[:, -1]]
            total_emb = torch.cat(total_emb, dim=0)
            total_emb = torch.mean(total_emb, dim=0)
            total_emb = total_emb.detach().cpu()

        response = compare_embedding(user_id, total_emb, time.time())

        if response["action_required"]:
            if response["action"] is not None:
                motion_description = f"Maybe {response['action']}"
                return {
                    "motion_description": [motion_description],
                    "full_joint": None,
                    "total_emb": total_emb,
                    "additional_info": {
                        "action": response["action"],
                        "meta_info": response["meta_info"],
                        "summary": response["summary"]
                    }
                }
            else:
                motion_description = ""
                with torch.no_grad():
                    inputs = torch.cat([acc, ori], dim=-1).to(self.device)
                    inputs = inputs.to(self.device)
                    all_joints = []
                    all_trans = []
                    for i in range(0, inputs.shape[0], 500):
                        full_joint, full_pose, velocity = self.watch_poser(inputs[i : i + 500].unsqueeze(0))
                        full_joint = full_joint.reshape(full_joint.shape[0], full_joint.shape[1], 24, 3)
                        trans = torch.cumsum(velocity, dim=1)
                        full_joint = torch.cat([full_joint[:, ::3, :, :], full_joint[:, -1:]], 1)
                        trans = torch.cat([trans[:, ::3, :], trans[:, -1].unsqueeze(1)], 1)
                        all_joints.append(full_joint)
                        all_trans.append(trans)
                    all_joints = torch.cat(all_joints, dim=1)
                    all_trans = torch.cat(all_trans, dim=1)

                    detailed_motion_description = get_motion_description(all_joints, all_trans)
                    # print("motion description:", detailed_motion_description)
                    detailed_motion_description[0] = motion_description + " and detailed motion is " + detailed_motion_description[0] + motion_description
                    return {
                        "motion_description": detailed_motion_description,
                        "full_joint": full_joint,
                        "total_emb": total_emb,
                        "additional_info": {
                            "action": response["action"],
                            "meta_info": response["meta_info"],
                            "summary": response["summary"]
                        }
                    }
        else:
            return {
                "motion_description": None,
                "full_joint": None,
                "total_emb": total_emb,
                "additional_info": {
                    "action": response["action"],
                    "meta_info": response["meta_info"],
                    "summary": response["summary"]
                }
            }