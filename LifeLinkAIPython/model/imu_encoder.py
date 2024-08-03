import torch.nn
import torch.nn as nn
from model.transformer.transformer_encoder import *

class LeftIMUEncoder(nn.Module):
    def __init__(
        self,
        imu_encoder_config,
    ):
        super().__init__()
        n_imu = imu_encoder_config["n_imu"]
        self.encoder = Encoder(n_imu, n_layers=imu_encoder_config["n_layers"], n_head=imu_encoder_config["n_head"], d_model=imu_encoder_config["d_model"])

        state_dict = torch.load(imu_encoder_config["model_path"], map_location="cpu")
        self.load_state_dict(state_dict)
        self.eval()


    def forward(self, imu):
        emb, _ = self.encoder(imu)
        return emb
