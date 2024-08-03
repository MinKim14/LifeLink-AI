# Simplification of https://github.com/OpenMotionLab/MotionGPT

import torch.nn as nn
from model.vmGpt.mGPT.archs.mgpt_vq import VQVae
from model.vmGpt.mGPT.archs.mgpt_lm import MLM

class VagueMotionGPT(nn.Module):
    def __init__(
        self,
    ):
        super().__init__()
        self.vae = VQVae()
        self.lm = MLM()

    def forward(self, batch, task="t2m"):
        texts = batch["text"]
        outputs, output_texts = self.lm.generate_direct(texts, do_sample=True)
        outputs = {
            "texts": output_texts,
        }
        return outputs

   