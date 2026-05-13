import os
import requests
import shutil

# Google Drive file ID from your link
GOOGLE_DRIVE_FILE_ID = "1Cl7RZEFL5YTjgjTMQDaBK66T17Y1tzSc"
MODEL_PATH = "Model/Ge_ResNet50V2_Model.keras"


def download_file_from_google_drive(file_id, destination):
    """Download file from Google Drive"""
    print(f"[Download] Downloading model from Google Drive...")
    
    URL = "https://docs.google.com/uc?export=download"
    session = requests.Session()
    
    # Get the download link
    params = {"id": file_id, "confirm": "t"}
    response = session.get(URL, params=params, stream=True)
    
    # Save the file
    total_size = int(response.headers.get('content-length', 0))
    downloaded = 0
    
    with open(destination, 'wb') as f:
        for chunk in response.iter_content(chunk_size=8192):
            if chunk:
                f.write(chunk)
                downloaded += len(chunk)
                # Print progress
                if total_size > 0:
                    percent = (downloaded / total_size) * 100
                    print(f"[Download] Progress: {percent:.1f}% ({downloaded/1024/1024:.1f}MB / {total_size/1024/1024:.1f}MB)")
    
    print(f"[Download] Model downloaded successfully to {destination}")


def ensure_model_exists():
    """Download model if it doesn't exist locally"""
    if os.path.exists(MODEL_PATH):
        file_size_mb = os.path.getsize(MODEL_PATH) / (1024 * 1024)
        print(f"[Model] Model already exists ({file_size_mb:.1f}MB)")
        return True
    
    print(f"[Model] Model not found. Downloading from Google Drive...")
    
    try:
        # Ensure Model directory exists
        os.makedirs("Model", exist_ok=True)
        
        # Download the model
        download_file_from_google_drive(GOOGLE_DRIVE_FILE_ID, MODEL_PATH)
        
        # Verify the file was downloaded
        if os.path.exists(MODEL_PATH):
            file_size_mb = os.path.getsize(MODEL_PATH) / (1024 * 1024)
            print(f"[Model] ✅ Model ready ({file_size_mb:.1f}MB)")
            return True
        else:
            print(f"[Model] ❌ Download failed - file not found")
            return False
            
    except Exception as e:
        print(f"[Model] ❌ Error downloading model: {e}")
        return False


if __name__ == "__main__":
    ensure_model_exists()
