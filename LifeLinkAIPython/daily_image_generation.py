
import os
from dotenv import load_dotenv
from vertexai.preview.vision_models import Image, ImageGenerationModel
import google.generativeai as genai

from PIL import Image, ImageDraw, ImageFont
from datetime import datetime

import firebase_admin
from firebase_admin import credentials, db, storage

import time
import schedule


class FirebaseVisualization:
    def __init__(self):
        load_dotenv()
        cred = credentials.Certificate(os.getenv("SERVICE_ACCOUNT_KEY_PATH"))
        firebase_admin.initialize_app(
            cred,
            {
                "storageBucket": os.getenv("STORAGE_BUCKET"),
                "databaseURL": os.getenv("DATABASE_URL"),
            },
        )
        os.makedirs("images", exist_ok=True)
        genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

        self.model = genai.GenerativeModel("gemini-pro")

    def create_visualization(self, user_id, date):
        # Get all history for the date
        day_summary = self.get_overview(user_id, date)
        if day_summary is None:
            print("No data found for the date")
            return None

        self.chat = self.model.start_chat()

        prompt_text = f"""
        Extract 4 major activities in time order from the following summary of daily activities: {day_summary}
        Only one key activity is allowed per sentence. Make sure the activities are very clear and verbose and time is described, for example, computer programming.
        Respond with only the activities in sentences with brief time and the order in which they occurred, in the first person view, separated by ";".
        """

        # Generate images based on activities
        generated_image_paths = self.generate_images_from_activities(
            prompt_text, user_id, date
        )

        if len(generated_image_paths) != 4:
            print("less than 4 images generated")
            return None

        # Combine images into a single image
        combined_image_path = f"images/{user_id}-{date}-combined_visualization.png"
        self.combine_images(generated_image_paths, combined_image_path)

        return combined_image_path

    def get_overview(self, user_id, date):
        new_ref = db.reference(user_id + f"/overview/{date}")
        overview = new_ref.get()
        if not overview:
            return None
        return overview

    def generate_images_from_activities(self, prompt_text, user_id, date):
        response = self.chat.send_message(prompt_text)
        activities = response.text.split(";")
        model = ImageGenerationModel.from_pretrained("imagegeneration@005")

        generated_image_paths = []
        for i, activity in enumerate(activities):
            activity = activity.strip().replace("\n", "")
            images = model.generate_images(
                prompt="generate clear happy illustration representing daily activity of a person described as in "
                + activity
            )
            # Save the first generated image to a file
            image_path = f"images/{user_id}-{date}-{i + 1}.jpg"
            images[0].save(image_path)
            generated_image_paths.append(image_path)

        return generated_image_paths

    def generate_images(self, prompt):
        return [Image.new("RGB", (256, 256), color=(73, 109, 137))]

    def combine_images(self, image_paths, output_path):
        # Target dimensions for the combined image
        target_width = 512
        target_height = 512

        images = [Image.open(path) for path in image_paths]

        resized_images = [img.resize((256, 256), Image.LANCZOS) for img in images]

        combined_image = Image.new("RGB", (target_width, target_height))
        positions = [(0, 0), (256, 0), (0, 256), (256, 256)]
        font = ImageFont.truetype("arial.ttf", 36)

        for i, (img, pos) in enumerate(zip(resized_images, positions)):
            combined_image.paste(img, pos)
            draw = ImageDraw.Draw(combined_image)
            label = str(i + 1)
            draw.text((pos[0] + 5, pos[1] + 5), label, fill="red", font=font)

        combined_image.save(output_path)

    def upload_image(self, file_path, storage_path):
        bucket = storage.bucket()
        blob = bucket.blob(storage_path)
        blob.upload_from_filename(file_path)
        print(f"File URL: {blob.public_url}")

    def check_and_upload_visualization(self, date):
        ref = db.reference("")
        data = ref.get()
        if data is None:
            return

        for user_id in data:
            print(user_id, date)
            combined_image_path = self.create_visualization(user_id, date)
            if combined_image_path is not None:
                self.upload_image(
                    combined_image_path, f"{user_id}/visualize/{date}.jpg"
                )

    def schedule_daily_task(self):
        # Fix the date to be used in the task
        date = datetime.now().strftime("%Y-%m-%d")

        # Schedule the task to run at 23:59 every day
        schedule.every().day.at("23:59").do(
            self.check_and_upload_visualization, date=date
        )

        while True:
            schedule.run_pending()
            time.sleep(1)


if __name__ == "__main__":
    firebase_visualization = FirebaseVisualization()
    firebase_visualization.schedule_daily_task()
