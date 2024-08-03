import torch.nn
import torch.nn as nn
from model.transformer.transformer_encoder import *

class WatchPoser(nn.Module):
    def __init__(
        self,
        poser_config,
    ):
        super().__init__()

        n_imu = poser_config["n_imu"]
        self.joint_s1 = TransformerEncoder(
            input_dim=n_imu,
            output_dim=poser_config["joint_output_dim"],
            d_model=poser_config["d_model"],
            d_embedding=poser_config["d_embedding"],
            n_layers=poser_config["n_layers"],
            n_head=poser_config["n_head"],
            dropout=poser_config["dropout"],
            n_position=poser_config["n_position"],
        )
        self.pose_s1 = TransformerEncoder(
            input_dim=n_imu + poser_config["joint_output_dim"],
            output_dim=poser_config["pose_output_dim"],
            d_model=poser_config["d_model"],
            d_embedding=poser_config["d_embedding"],
            n_layers=poser_config["n_layers"],
            n_head=poser_config["n_head"],
            dropout=poser_config["dropout"],
            n_position=poser_config["n_position"],
        )
        self.vel = TransformerEncoder(
            input_dim=n_imu + poser_config["joint_output_dim"],
            output_dim=poser_config["vel_output_dim"],
            d_model=poser_config["d_model"],
            d_embedding=poser_config["d_embedding"] + 1,
            n_layers=poser_config["n_layers"],
            n_head=poser_config["n_head"],
            dropout=poser_config["dropout"],
            n_position=poser_config["n_position"],
        )

        poser_state_dict = torch.load(poser_config["model_path"], map_location="cpu")
        self.load_state_dict(poser_state_dict)
        self.eval()
                             

    def forward(self, imu):
        full_joint = self.joint_s1(imu)
        full_pose = self.pose_s1(torch.cat((imu, full_joint), dim=-1))
        velocity = self.vel(torch.cat((imu, full_joint), dim=2))
        return (
            full_joint,
            full_pose,
            velocity,
        )
