import os
import os.path as osp

import numpy as np
import torch
import json

def vector_cross_matrix(x: torch.Tensor):
    r"""
    Get the skew-symmetric matrix :math:`[v]_\times\in so(3)` for each vector3 `v`. (torch, batch)

    :param x: Tensor that can reshape to [batch_size, 3].
    :return: The skew-symmetric matrix in shape [batch_size, 3, 3].
    """
    x = x.view(-1, 3)
    zeros = torch.zeros(x.shape[0], device=x.device)
    return torch.stack((zeros, -x[:, 2], x[:, 1],
                        x[:, 2], zeros, -x[:, 0],
                        -x[:, 1], x[:, 0], zeros), dim=1).view(-1, 3, 3)

def normalize_tensor(x: torch.Tensor, dim=-1, return_norm=False):
    norm = x.norm(dim=dim, keepdim=True)
    normalized_x = x / norm
    return normalized_x if not return_norm else (normalized_x, norm)

def axis_angle_to_rotation_matrix(a: torch.Tensor):
    axis, angle = normalize_tensor(a.view(-1, 3), return_norm=True)
    axis[torch.isnan(axis)] = 0
    i_cube = torch.eye(3, device=a.device).expand(angle.shape[0], 3, 3)
    c, s = angle.cos().view(-1, 1, 1), angle.sin().view(-1, 1, 1)
    r = (
        c * i_cube
        + (1 - c) * torch.bmm(axis.view(-1, 3, 1), axis.view(-1, 1, 3))
        + s * vector_cross_matrix(axis)
    )
    return r

class WatchDataParser:
    def __init__(self, data_dir, parse_folder):
        self.data_dir = data_dir
        self.parse_folder = parse_folder

        self.acc_gyro_file_list = {}
        for file in os.listdir(data_dir):
            data_type, data_time = self._parse_file_name(file)
            if data_time not in self.acc_gyro_file_list:
                self.acc_gyro_file_list[data_time] = {}
            self.acc_gyro_file_list[data_time][data_type] = file

        # sort the data by time
        self.acc_gyro_file_list = dict(sorted(self.acc_gyro_file_list.items()))
        self.acc = None
        self.ori = None
        self.total_data = []
        for key in self.acc_gyro_file_list:
            acc_ori_data = self._read_data(self.acc_gyro_file_list[key])
            if acc_ori_data is None:
                continue
            self.total_data.append(acc_ori_data)

        if self.total_data:
            self.total_data = np.concatenate(self.total_data, axis=0)
            acc, ori = self._transform_to_amass(self.total_data)
            parse_file_dir = osp.join(self.parse_folder, osp.basename(data_dir) + "_parse")
            os.makedirs(parse_file_dir, exist_ok=True)
            np.save(osp.join(parse_file_dir, "acc.npy"), acc.numpy())
            np.save(osp.join(parse_file_dir, "ori.npy"), ori.numpy())
            self.acc = acc
            self.ori = ori
            # Call the inference function with parsed data

    def get_acc_ori(self):
        return self.acc, self.ori

    def _parse_file_name(self, file_name):
        data_type = file_name.split("_")[0]
        data_time = file_name.split("_")[1]
        return data_type, data_time

    def _transform_to_amass(self, data):
        acc = data[:, :3]
        ori = data[:, 3:]

        acc = torch.tensor(acc).float()
        ori = torch.tensor(ori).float()

        rot_ori = axis_angle_to_rotation_matrix(ori)
        global_acc = torch.matmul(rot_ori, acc.unsqueeze(-1)).squeeze(-1)
        global_acc[:, 2] += 1

        amass_global_acc = global_acc[:, [0, 2, 1]]
        amass_global_acc[:, 1] = -amass_global_acc[:, 1]

        amass_ori = ori[:, [0, 2, 1]]
        amass_ori[:, 2] = -amass_ori[:, 2]
        amass_rot_ori = axis_angle_to_rotation_matrix(amass_ori).reshape(-1, 9)
        return amass_global_acc, amass_rot_ori

    def _read_data(self, acc_gyro_dict):
        if "acc" not in acc_gyro_dict or "gyro" not in acc_gyro_dict:
            return None
        accs = acc_gyro_dict["acc"]
        gyros = acc_gyro_dict["gyro"]
        accs = json.load(open(osp.join(self.data_dir, accs)))
        gyros = json.load(open(osp.join(self.data_dir, gyros)))
        if "error" in accs or "error" in gyros:
            return None
        acc_data = self._read_acc(accs)
        gyro_data = self._read_gyro(gyros)
        if(acc_data.shape[0] == 0 or gyro_data.shape[0] == 0):
            return None
        if(acc_data.shape[0] != gyro_data.shape[0]):
            min_length = min(acc_data.shape[0], gyro_data.shape[0])
            acc_data = acc_data[-min_length:]
            gyro_data = gyro_data[-min_length:]
        acc_ori_data = np.concatenate([acc_data[:, 1:], gyro_data[:, 1:]], axis=1)
        return acc_ori_data

    def _read_acc(self, accs):
        total_data = []
        for acc in accs["Accs"]:
            t, x, y, z = acc["time"], acc["acc_X"], acc["acc_Y"], acc["acc_Z"]
            total_data.append([t, x, y, z])
        return np.array(total_data)

    def _read_gyro(self, gyros):
        total_data = []
        for gyro in gyros["Gyros"]:
            t, x, y, z = gyro["time"], gyro["pitch_X"], gyro["roll_Y"], gyro["yaw_Z"]
            total_data.append([t, x, y, z])
        return np.array(total_data)
    