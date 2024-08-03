import os
import os.path as osp
from dotenv import load_dotenv

import time
from datetime import datetime, timedelta
import yaml

import firebase_admin
from firebase_admin import credentials, storage

from data.data_parser import WatchDataParser
from firebase_realtime_database import FirebaseHandler
from gemini_communicator import GeminiCommunicator

from model.inference_model import InferenceModel
from model.model_inference_handler import ModelInferenceHandler


class FirebaseDataHandler:
    def __init__(self, model_config_path = "configs/model_config.yaml", interval=120):
        load_dotenv()
        with open(model_config_path, 'r') as file:
            model_config = yaml.safe_load(file)

        cred = credentials.Certificate(os.getenv("SERVICE_ACCOUNT_KEY_PATH"))
        firebase_admin.initialize_app(cred, {
            'storageBucket': os.getenv("STORAGE_BUCKET"),
            "databaseURL": os.getenv("DATABASE_URL"),
        })
        self.bucket = storage.bucket()
        self.gemini_model = GeminiCommunicator(api_key=os.getenv("GEMINI_API_KEY"))
        self.firebase_handler = FirebaseHandler(self.gemini_model)
        self.download_folder = os.getenv("DOWNLOAD_FOLDER")
        self.parse_folder = os.getenv("PARSE_FOLDER")
        self.interval = interval
        
        self.inference_model = InferenceModel(model_config['inference_model'])
        self.model_inference_handler = ModelInferenceHandler(self.inference_model, self.firebase_handler, self.gemini_model)

        os.makedirs(self.download_folder, exist_ok=True)
        os.makedirs(self.parse_folder, exist_ok=True)

    def _list_files_in_storage(self):
        blobs = self.bucket.list_blobs(prefix="")
        return blobs

    def _download_file_from_storage(self, file_name, local_file_path):
        blob = self.bucket.blob(file_name)
        try:
            blob.download_to_filename(local_file_path)
            return True
        except:
            return False

    def _extract_file_timestamp(self, file_name):
        try:
            _, file_time_str = file_name.split("_")
            file_time = datetime.fromtimestamp(float(file_time_str))
            return file_time
        except Exception as e:
            print(f"Error parsing file time for {file_name}: {e}")
            return None

    def _is_file_within_cutoff(self, file_time, cutoff_date):
        return file_time >= cutoff_date

    def _generate_interval_path(self, user_id, file_time, base_folder):
        interval_start = file_time.replace(minute=(file_time.minute // 5) * 5, second=0, microsecond=0)
        interval_folder = interval_start.strftime("%Y%m%d_%H%M")
        user_dir = osp.join(base_folder, user_id)
        os.makedirs(user_dir, exist_ok=True)
        local_path = osp.join(user_dir, interval_folder)
        os.makedirs(local_path, exist_ok=True)
        return local_path
    
    def _extract_user_id_from_path(self, folder):
        return folder.split("\\")[-2]

    def _process_and_infer_data(self, folders_to_parse):
        for folder in folders_to_parse:
            user_id = self._extract_user_id_from_path(folder)
            cur_greeting = self.gemini_model.generate_greeting()
            self.firebase_handler.add_greeting(user_id, cur_greeting)
            cur_dataset = WatchDataParser(folder, self.parse_folder)
            acc, ori = cur_dataset.get_acc_ori()
            if(acc is None or ori is None):
                continue

            self.model_inference_handler.run(user_id, acc, ori)

    def delete_file_from_storage(self, blob_name):
        blob = self.bucket.blob(blob_name)
        blob.delete()

    def start_monitoring(self):
        try:
            while True:
                print("Checking for new files...")
                new_blobs = set(self._list_files_in_storage())
                cutoff_time = datetime.now() - timedelta(hours=12)

                folder_need_to_be_parsed = []
                for blob in new_blobs:
                    file_name = blob.name
                    if("visualize" in file_name):
                        continue
                    user_id = file_name.split("/")[0]
                    base_file_name = file_name.split("/")[-1]
                    file_time = self._extract_file_timestamp(base_file_name)
                    if file_time and self._is_file_within_cutoff(file_time, cutoff_time):
                        local_folder = self._generate_interval_path(user_id, file_time, self.download_folder)
                        local_path = osp.join(local_folder, base_file_name)
                        download_status = self._download_file_from_storage(file_name, local_path)

                        if download_status:
                            if(local_folder not in folder_need_to_be_parsed):
                                folder_need_to_be_parsed.append(local_folder)
                            self.delete_file_from_storage(file_name)
                    else:
                        self.delete_file_from_storage(file_name)

                self._process_and_infer_data(folder_need_to_be_parsed)
                time.sleep(self.interval)
        except KeyboardInterrupt:
            print("Shutting down gracefully...")



if __name__ == '__main__':
    downloader = FirebaseDataHandler(
        download_folder='download_data',
        parse_folder='parsed_data',
    )
    try:
        downloader.start_monitoring()
    except KeyboardInterrupt:
        print("Shutting down gracefully...")