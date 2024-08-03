# Data processing code from https://github.com/EricGuo5513/HumanML3D

import os
import numpy as np
import torch
from model.common.skeleton import Skeleton
from model.common.quaternion import *
from model.paramUtil import *

l_idx1, l_idx2 = 5, 8
fid_r, fid_l = [8, 11], [7, 10]
face_joint_indx = [2, 1, 17, 16]
r_hip, l_hip = 2, 1
joints_num = 22

mean, std = np.load("model/humanml3d/Mean.npy"), np.load("model/humanml3d/Std.npy")
example_data = np.load(os.path.join('model/joints/000021.npy'))
example_data = example_data.reshape(len(example_data), -1, 3)
example_data = torch.from_numpy(example_data)
n_raw_offsets = torch.from_numpy(t2m_raw_offsets)
kinematic_chain = t2m_kinematic_chain
tgt_skel = Skeleton(n_raw_offsets, kinematic_chain, 'cpu')
tgt_offsets = tgt_skel.get_offsets_joints(example_data[0])

def uniform_skeleton(positions, target_offset):
    src_skel = Skeleton(n_raw_offsets, kinematic_chain, "cpu")
    src_offset = src_skel.get_offsets_joints(torch.from_numpy(positions[0]))
    src_offset = src_offset.numpy()
    tgt_offset = target_offset.numpy()
    """Calculate Scale Ratio as the ratio of legs"""
    src_leg_len = np.abs(src_offset[l_idx1]).max() + np.abs(src_offset[l_idx2]).max()
    tgt_leg_len = np.abs(tgt_offset[l_idx1]).max() + np.abs(tgt_offset[l_idx2]).max()

    scale_rt = tgt_leg_len / src_leg_len
    src_root_pos = positions[:, 0]
    tgt_root_pos = src_root_pos * scale_rt

    """Inverse Kinematics"""
    quat_params = src_skel.inverse_kinematics_np(positions, face_joint_indx)

    """Forward Kinematics"""
    src_skel.set_offset(target_offset)
    new_joints = src_skel.forward_kinematics_np(quat_params, tgt_root_pos)
    return new_joints

def process_file(positions, feet_thre):
    """Uniform Skeleton"""
    positions = uniform_skeleton(positions, tgt_offsets)

    """Put on Floor"""
    floor_height = positions.min(axis=0).min(axis=0)[1]
    positions[:, :, 1] -= floor_height

    """XZ at origin"""
    root_pos_init = positions[0]
    root_pose_init_xz = root_pos_init[0] * np.array([1, 0, 1])
    positions = positions - root_pose_init_xz

    """All initially face Z+"""
    r_hip, l_hip, sdr_r, sdr_l = face_joint_indx
    across1 = root_pos_init[r_hip] - root_pos_init[l_hip]
    across2 = root_pos_init[sdr_r] - root_pos_init[sdr_l]
    across = across1 + across2
    across = across / np.sqrt((across**2).sum(axis=-1))[..., np.newaxis]

    forward_init = np.cross(np.array([[0, 1, 0]]), across, axis=-1)
    forward_init = (
        forward_init / np.sqrt((forward_init**2).sum(axis=-1))[..., np.newaxis]
    )

    target = np.array([[0, 0, 1]])
    root_quat_init = qbetween_np(forward_init, target)
    root_quat_init = np.ones(positions.shape[:-1] + (4,)) * root_quat_init

    positions = qrot_np(root_quat_init, positions)

    """New ground truth positions"""
    global_positions = positions.copy()

    """ Get Foot Contacts """

    def foot_detect(positions, thres):
        velfactor, heightfactor = np.array([thres, thres]), np.array([3.0, 2.0])

        feet_l_x = (positions[1:, fid_l, 0] - positions[:-1, fid_l, 0]) ** 2
        feet_l_y = (positions[1:, fid_l, 1] - positions[:-1, fid_l, 1]) ** 2
        feet_l_z = (positions[1:, fid_l, 2] - positions[:-1, fid_l, 2]) ** 2
        feet_l = ((feet_l_x + feet_l_y + feet_l_z) < velfactor).astype(np.float32)

        feet_r_x = (positions[1:, fid_r, 0] - positions[:-1, fid_r, 0]) ** 2
        feet_r_y = (positions[1:, fid_r, 1] - positions[:-1, fid_r, 1]) ** 2
        feet_r_z = (positions[1:, fid_r, 2] - positions[:-1, fid_r, 2]) ** 2
        feet_r = (((feet_r_x + feet_r_y + feet_r_z) < velfactor)).astype(np.float32)
        return feet_l, feet_r

    #
    feet_l, feet_r = foot_detect(positions, feet_thre)

    """Quaternion and Cartesian representation"""
    r_rot = None

    def get_rifke(positions):
        """Local pose"""
        positions[..., 0] -= positions[:, 0:1, 0]
        positions[..., 2] -= positions[:, 0:1, 2]
        """All pose face Z+"""
        positions = qrot_np(
            np.repeat(r_rot[:, None], positions.shape[1], axis=1), positions
        )
        return positions

    def get_cont6d_params(positions):
        skel = Skeleton(n_raw_offsets, kinematic_chain, "cpu")
        quat_params = skel.inverse_kinematics_np(
            positions, face_joint_indx, smooth_forward=True
        )

        """Quaternion to continuous 6D"""
        cont_6d_params = quaternion_to_cont6d_np(quat_params)
        r_rot = quat_params[:, 0].copy()
        """Root Linear Velocity"""
        velocity = (positions[1:, 0] - positions[:-1, 0]).copy()
        velocity = qrot_np(r_rot[1:], velocity)
        """Root Angular Velocity"""
        r_velocity = qmul_np(r_rot[1:], qinv_np(r_rot[:-1]))
        return cont_6d_params, r_velocity, velocity, r_rot

    cont_6d_params, r_velocity, velocity, r_rot = get_cont6d_params(positions)
    positions = get_rifke(positions)

    """Root height"""
    root_y = positions[:, 0, 1:2]

    """Root rotation and linear velocity"""
    r_velocity = np.arcsin(r_velocity[:, 2:3])
    l_velocity = velocity[:, [0, 2]]
    root_data = np.concatenate([r_velocity, l_velocity, root_y[:-1]], axis=-1)

    """Get Joint Rotation Representation"""
    rot_data = cont_6d_params[:, 1:].reshape(len(cont_6d_params), -1)

    """Get Joint Rotation Invariant Position Represention"""
    ric_data = positions[:, 1:].reshape(len(positions), -1)

    """Get Joint Velocity Representation"""
    local_vel = qrot_np(
        np.repeat(r_rot[:-1, None], global_positions.shape[1], axis=1),
        global_positions[1:] - global_positions[:-1],
    )
    local_vel = local_vel.reshape(len(local_vel), -1)

    data = root_data
    data = np.concatenate([data, ric_data[:-1]], axis=-1)
    data = np.concatenate([data, rot_data[:-1]], axis=-1)
    data = np.concatenate([data, local_vel], axis=-1)
    data = np.concatenate([data, feet_l, feet_r], axis=-1)
    return data, global_positions, positions, l_velocity