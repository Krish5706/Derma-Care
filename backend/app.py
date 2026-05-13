from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_pymongo import PyMongo
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
import jwt
import datetime
from datetime import timezone
from functools import wraps
import os
import uuid
import base64
from PIL import Image
from bson.objectid import ObjectId
import io
import numpy as np
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
import requests
from Model.standalone_predictor import predict_skin_condition
import google.generativeai as genai
from dotenv import load_dotenv
from download_model import ensure_model_exists

# Load environment variables from backend/.env (development only). In production
# prefer real environment variables or a secrets manager.
load_dotenv()

# Download ML model from Google Drive if not present (important for Railway deployment)
ensure_model_exists()

app = Flask(__name__)
# Allow all origins for testing (use specific origins in production)
CORS(app, resources={r"/*": {"origins": "*"}})  # Changed to allow all origins

# Configurations
app.config['MONGO_URI'] = os.environ.get('MONGO_URI', '')
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', '')

# Google OAuth Configuration
GOOGLE_CLIENT_ID = os.environ.get('GOOGLE_CLIENT_ID', '')

mongo = PyMongo(app)
users = mongo.db.users
analyses = mongo.db.analyses
chat_history = mongo.db.chat_history
# New collection for prediction history items (image + prediction stored together)
predictions = mongo.db.predictions
# New collection for AI Skin Advisor history
advisor_history_collection = mongo.db.advisor_history

# New collection for feedback
feedback = mongo.db.feedback

# Configure upload folder
UPLOAD_FOLDER = 'Uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

# Load the model and encoder at startup
# Use the new .keras model and class names json
model_path = os.path.join('Model', 'Ge_ResNet50V2_Model.keras')
class_names_path = os.path.join('Model', 'skin_disease_class_names.json')

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            token = request.headers['Authorization'].split(' ')[1]
        if not token:
            return jsonify({'message': 'Token is missing!'}), 401
        try:
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
            current_user = users.find_one({'email': data['email']})
        except Exception as e:
            return jsonify({'message': 'Token is invalid!'}), 401
        return f(current_user, *args, **kwargs)
    return decorated

@app.route('/chat/history', defaults={'chat_id': None}, methods=['POST', 'GET'])
@app.route('/chat/history/<chat_id>', methods=['GET'])
@token_required
def handle_chat_history(current_user, chat_id):
    if request.method == 'POST':
        data = request.get_json()
        if not data or 'messages' not in data or not data['messages']:
            return jsonify({'message': 'Missing or empty messages data'}), 400

        chat_id = data.get('chat_id')
        messages = data['messages']
        title = messages[0].get('text', 'Untitled Chat')

        # Use device timestamp if provided, otherwise use server time
        timestamp = data.get('timestamp')
        if timestamp:
            # Parse the ISO string and ensure it's in UTC+5:30 for storage
            timestamp = datetime.datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            # Convert to UTC+5:30
            timestamp = timestamp.astimezone(datetime.timezone(datetime.timedelta(hours=5, minutes=30))).isoformat()
        else:
            # Use current time in UTC+5:30
            timestamp = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=5, minutes=30))).isoformat()

        if chat_id:
            # Update existing chat
            try:
                obj_id = ObjectId(chat_id)
            except Exception:
                return jsonify({'message': 'Invalid chat ID format'}), 400

            result = chat_history.update_one(
                {'_id': obj_id, 'user_email': current_user['email']},
                {
                    '$set': {
                        'messages': messages,
                        'title': title,
                        'timestamp': timestamp
                    }
                }
            )
            if result.matched_count == 0:
                return jsonify({'message': 'Chat not found or access denied'}), 404
            return jsonify({'message': 'Chat history updated successfully'}), 200
        else:
            # Create new chat
            chat_session = {
                'user_email': current_user['email'],
                'title': title,
                'messages': messages,
                'timestamp': timestamp
            }
            result = chat_history.insert_one(chat_session)
            return jsonify({
                'message': 'Chat history saved successfully',
                'chat_id': str(result.inserted_id)
            }), 201
    
    if request.method == 'GET':
        if chat_id:
            try:
                obj_id = ObjectId(chat_id)
            except Exception:
                return jsonify({'message': 'Invalid chat ID format'}), 400

            chat_session = chat_history.find_one({
                '_id': obj_id,
                'user_email': current_user['email']
            })

            if not chat_session:
                return jsonify({'message': 'Chat session not found or access denied'}), 404
            
            # Ensure timestamp is a string for backward compatibility
            if 'timestamp' in chat_session and isinstance(chat_session['timestamp'], datetime.datetime):
                chat_session['timestamp'] = chat_session['timestamp'].isoformat()

            chat_session['_id'] = str(chat_session['_id'])
            return jsonify(chat_session), 200
        else:
            user_chats = chat_history.find({'user_email': current_user['email']}).sort('timestamp', -1)
            history = []
            for chat in user_chats:
                timestamp = chat.get('timestamp')
                if isinstance(timestamp, datetime.datetime):
                    timestamp = timestamp.isoformat()
                
                history.append({
                    'id': str(chat['_id']),
                    'title': chat['title'],
                    'timestamp': timestamp
                })
            return jsonify(history), 200

@app.route('/chat/history/delete', methods=['POST'])
@token_required
def delete_chat_history(current_user):
    data = request.get_json()
    if not data or 'ids' not in data:
        return jsonify({'message': 'Missing chat IDs'}), 400

    chat_ids_str = data['ids']
    if not isinstance(chat_ids_str, list):
        return jsonify({'message': 'IDs should be a list'}), 400

    try:
        object_ids = [ObjectId(cid) for cid in chat_ids_str]
    except Exception:
        return jsonify({'message': 'Invalid chat ID format'}), 400

    result = chat_history.delete_many({
        '_id': {'$in': object_ids},
        'user_email': current_user['email']
    })

    if result.deleted_count > 0:
        return jsonify({'message': f'{result.deleted_count} conversations deleted successfully'}), 200
    else:
        return jsonify({'message': 'No conversations found to delete'}), 404

@app.route('/auth/google', methods=['POST'])
def google_auth():
    try:
        data = request.get_json()
        id_token_str = data.get('idToken')
        
        if not id_token_str:
            return jsonify({'message': 'ID token is required'}), 400
        
        # Verify the Google ID token
        try:
            idinfo = id_token.verify_oauth2_token(
                id_token_str,
                google_requests.Request(),
                GOOGLE_CLIENT_ID
            )

            # Get user info from Google
            google_user_id = idinfo['sub']
            email = idinfo['email']
            name = idinfo.get('name', '')
            picture = idinfo.get('picture', '')
            print(f"Google token verified for email: {email}")

        except ValueError as e:
            print(f"Invalid Google token: {e}")
            return jsonify({'message': 'Invalid Google token'}), 401
        
        # Check if user exists
        user = users.find_one({'email': email})

        if not user:
            # Create new user
            user = {
                'username': name,
                'email': email,
                'google_id': google_user_id,
                'profile_picture': picture,
                'auth_provider': 'google',
                'created_at': datetime.datetime.utcnow()
            }
            users.insert_one(user)
            print(f"New user created for {email}")
        else:
            # Update user info if needed
            users.update_one(
                {'email': email},
                {'$set': {
                    'username': name,
                    'profile_picture': picture,
                    'last_login': datetime.datetime.utcnow()
                }}
            )
            print(f"Existing user updated for {email}")

        # Generate JWT token
        token = jwt.encode({
            'email': email,
            'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
        }, app.config['SECRET_KEY'], algorithm="HS256")
        print(f"JWT token generated for {email}")

        return jsonify({'token': token, 'user': {
            'username': user.get('username'),
            'email': user.get('email'),
            'profile_picture': user.get('profile_picture')
        }}), 200

    except Exception as e:
        print(f"Error in /auth/google: {e}")
        return jsonify({'message': str(e)}), 500

@app.route('/predict', methods=['POST'])
def predict():
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400

    file = request.files['image']

    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        # Ensure the uploads directory exists
        if not os.path.exists(UPLOAD_FOLDER):
            os.makedirs(UPLOAD_FOLDER)
        image_path = os.path.join(UPLOAD_FOLDER, filename)
        file.save(image_path)

        try:
            # Use the TensorFlow .keras model for prediction
            pred_class, confidence = predict_skin_condition(
                image_path=image_path,
                model_path=model_path,
                class_names_path=class_names_path
            )
            # Mapping from model class name to user-friendly display name
            display_name_map = {
                "Acne And Rosacea Photos": "Acne Vulgaris and Rosacea",
                "Ba Impetigo": "Bacterial Impetigo",
                "Bullous Disease Photos": "Bullous Pemphigoid",
                "Eczema Photos": "Eczema (Atopic Dermatitis)",
                "Exanthems And Drug Eruptions": "Drug-Induced Exanthem",
                "Fu Nail Fungus": "Fungal Nail Infection",
                "Fu Ringworm": "Ringworm of the Body",
                "Heathy": "Healthy Skin",
                "Rashes": "Rashes",
                "Vi Chickenpox": "Chickenpox"
            }
            display_name = display_name_map.get(pred_class, pred_class)
            print(f"[Prediction] Predicted Class: {pred_class}, Display Name: {display_name}, Confidence: {confidence:.2%}")
            return jsonify({'predicted_class': pred_class, 'display_name': display_name, 'confidence': confidence})
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    else:
        return jsonify({'error': 'File type not allowed'}), 400

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    print(f"Received register request: {data}")  # Debug log
    if not data or not data.get('email') or not data.get('password') or not data.get('username'):
        return jsonify({'message': 'Missing fields!'}), 400
    if users.find_one({'email': data['email']}):
        return jsonify({'message': 'User already exists!'}), 409
    hashed_pw = generate_password_hash(data['password'])
    user = {
        'username': data['username'],
        'email': data['email'],
        'password': hashed_pw,
        'created_at': datetime.datetime.utcnow()
    }
    users.insert_one(user)
    return jsonify({'message': 'User registered successfully!'}), 201

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    print(f"Received login request: {data}")  # Debug log
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({'message': 'Missing fields!'}), 400
    user = users.find_one({'email': data['email']})
    if not user or not check_password_hash(user['password'], data['password']):
        return jsonify({'message': 'Invalid credentials!'}), 401
    token = jwt.encode({
        'email': user['email'],
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
    }, app.config['SECRET_KEY'], algorithm="HS256")
    return jsonify({'token': token, 'username': user['username'], 'email': user['email']}), 200

@app.route('/auth/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json()
    if not data or not data.get('email') or not data.get('new_password'):
        return jsonify({'message': 'Email and new password are required'}), 400

    email = data.get('email')
    new_password = data.get('new_password')

    user = users.find_one({'email': email})

    if not user:
        return jsonify({'message': 'No account found with that email address.'}), 404

    if 'password' not in user:
        return jsonify({'message': 'No account found with that email address.'}), 404

    hashed_pw = generate_password_hash(new_password)
    users.update_one({'email': email}, {'$set': {'password': hashed_pw}})

    print(f"Password has been reset for: {email}")
    return jsonify({'message': 'Password has been reset successfully.'}), 200

@app.route('/profile', methods=['GET'])
@token_required
def profile(current_user):
    user_data = {
        'username': current_user['username'],
        'email': current_user['email'],
        'created_at': str(current_user['created_at'])  # Convert datetime to string
    }
    return jsonify({'user': user_data}), 200

def mock_ml_analysis(image_path):
    """
    Mock ML analysis function. In a real implementation, this would call
    your trained skin analysis model.
    """
    import random
    
    conditions = [
        {
            'condition': 'Healthy Skin',
            'severity': 'Normal',
            'confidence': random.uniform(90, 98),
            'description': 'Your skin appears healthy with no visible signs of concerning conditions.',
            'features': [
                'Even skin tone',
                'No visible lesions',
                'Good texture',
                'Appropriate pigmentation'
            ],
            'recommendations': [
                'Continue your current skincare routine',
                'Use sunscreen daily (SPF 30+)',
                'Stay hydrated',
                'Regular skin check-ups'
            ]
        },
        {
            'condition': 'Acne',
            'severity': 'Mild',
            'confidence': random.uniform(80, 95),
            'description': 'Mild acne detected. This is a common skin condition that can be managed with proper care.',
            'features': [
                'Small inflammatory lesions',
                'Some comedones present',
                'Localized inflammation',
                'No scarring detected'
            ],
            'recommendations': [
                'Use gentle, non-comedogenic cleanser',
                'Apply topical retinoids or salicylic acid',
                'Avoid touching affected areas',
                'Consider consulting a dermatologist'
            ]
        },
        {
            'condition': 'Sun Damage',
            'severity': 'Moderate',
            'confidence': random.uniform(75, 90),
            'description': 'Signs of sun damage are visible. Early intervention can help prevent further damage.',
            'features': [
                'Hyperpigmentation spots',
                'Uneven skin tone',
                'Fine lines present',
                'Texture changes'
            ],
            'recommendations': [
                'Use broad-spectrum sunscreen daily',
                'Apply vitamin C serum',
                'Consider professional treatments',
                'Regular dermatologist check-ups'
            ]
        }
    ]
    
    # Randomly select a condition for demo purposes
    selected = random.choice(conditions)
    
    return {
        'condition': selected['condition'],
        'severity': selected['severity'],
        'confidence': selected['confidence'],
        'description': selected['description'],
        'features': selected['features'],
        'recommendations': selected['recommendations'],
            'timestamp': datetime.datetime.now().isoformat(),
        'model_version': 'DermaCare-AI-v1.0'
    }

# =========================
# Prediction History Routes
# =========================

@app.route('/history', methods=['POST'])
@token_required
def save_prediction_history(current_user):
    """
    Save a prediction record with the uploaded image (stored as base64) and prediction data.
    Expects multipart/form-data with fields:
      - image: file
      - prediction: str
      - confidence: float or str
    """
    try:
        if 'image' not in request.files:
            return jsonify({'message': 'No image file provided'}), 400

        file = request.files['image']
        if file.filename == '':
            return jsonify({'message': 'No file selected'}), 400

        if not allowed_file(file.filename):
            return jsonify({'message': 'Invalid file type. Please upload a PNG, JPG, or JPEG image.'}), 400

        image_bytes = file.read()
        mime_type = file.mimetype or 'application/octet-stream'

        prediction = request.form.get('prediction')
        confidence = request.form.get('confidence')

        if prediction is None or confidence is None:
            return jsonify({'message': 'Missing prediction or confidence'}), 400

        try:
            confidence_val = float(confidence)
        except Exception:
            return jsonify({'message': 'Invalid confidence value'}), 400

        record = {
            'user_id': str(current_user['_id']),
            'user_email': current_user['email'],
            'image_binary': image_bytes,  # Store as binary
            'image_mime': mime_type,
            'prediction': prediction,
            'confidence': confidence_val,
            'created_at': datetime.datetime.utcnow()
        }

        result = predictions.insert_one(record)
        print(f"[History] Saved prediction for {current_user['email']} at {record['created_at']}")
        return jsonify({'message': 'Saved', 'id': str(result.inserted_id)}), 201
    except Exception as e:
        return jsonify({'message': f'Error saving prediction: {str(e)}'}), 500

@app.route('/history', methods=['GET'])
@token_required
def fetch_prediction_history(current_user):
    """
    Return latest prediction history for authenticated user including base64 images.
    """
    try:
        items = predictions.find({'user_email': current_user['email']}).sort('created_at', -1).limit(100)
        history = []
        for it in items:
            created_at = it.get('created_at')
            if isinstance(created_at, datetime.datetime):
                created_at = created_at.isoformat()
            history.append({
                'id': str(it.get('_id')),
                'prediction': it.get('prediction'),
                'confidence': it.get('confidence'),
                'image_base64': base64.b64encode(it.get('image_binary')).decode('utf-8') if it.get('image_binary') else None,
                'image_mime': it.get('image_mime', 'image/jpeg'),
                'created_at': created_at,
            })
        print(f"[History] Fetched {len(history)} items for {current_user['email']}")
        return jsonify(history), 200
    except Exception as e:
        return jsonify({'message': f'Error fetching history: {str(e)}'}), 500

@app.route('/history/clear', methods=['DELETE'])
@token_required
def clear_prediction_history(current_user):
    """Clear all prediction history for the current user."""
    try:
        result = predictions.delete_many({'user_email': current_user['email']})
        print(f"[History] Cleared {result.deleted_count} records for {current_user['email']}")
        return jsonify({
            'message': 'History cleared successfully',
            'deleted_count': result.deleted_count
        }), 200
    except Exception as e:
        return jsonify({'message': f'Error clearing history: {str(e)}'}), 500

@app.route('/history/<item_id>', methods=['DELETE'])
@token_required
def delete_prediction_history_item(current_user, item_id):
    """Delete a specific prediction history item for the current user."""
    try:
        try:
            obj_id = ObjectId(item_id)
        except Exception:
            return jsonify({'message': 'Invalid history item ID format'}), 400

        result = predictions.delete_one({
            '_id': obj_id,
            'user_email': current_user['email']
        })

        if result.deleted_count == 0:
            return jsonify({'message': 'History item not found or access denied'}), 404

        print(f"[History] Deleted item {item_id} for {current_user['email']}")
        return jsonify({'message': f'History item {item_id} deleted successfully'}), 200
    except Exception as e:
        return jsonify({'message': f'Error deleting history item: {str(e)}'}), 500

@app.route('/analyze-skin', methods=['POST'])
@token_required
def analyze_skin(current_user):
    try:
        if 'image' not in request.files:
            return jsonify({'message': 'No image file provided'}), 400
        
        file = request.files['image']
        if file.filename == '':
            return jsonify({'message': 'No file selected'}), 400
        
        if file and allowed_file(file.filename):
            # Generate unique filename
            filename = secure_filename(f"{uuid.uuid4()}_{file.filename}")
            filepath = os.path.join(UPLOAD_FOLDER, filename)
            file.save(filepath)
            
            # Perform ML analysis (mock for now)
            analysis_result = mock_ml_analysis(filepath)
            
            # Store analysis in database
            analysis_record = {
                'user_id': str(current_user['_id']),
                'user_email': current_user['email'],
                'image_path': filepath,
                'analysis_result': analysis_result,
                'created_at': datetime.datetime.utcnow()
            }
            
            analyses.insert_one(analysis_record)
            
            return jsonify(analysis_result), 200
        else:
            return jsonify({'message': 'Invalid file type. Please upload a PNG, JPG, or JPEG image.'}), 400
            
    except Exception as e:
        return jsonify({'message': f'Error analyzing image: {str(e)}'}), 500

@app.route('/analysis-history', methods=['GET'])
@app.route('/analysis-history/<user_id>', methods=['GET'])
@token_required
def get_analysis_history(current_user, user_id):
    try:
        # Basic check to ensure the requesting user is the one they claim to be
        # A more robust system might involve admin roles
        if str(current_user['_id']) != user_id:
            return jsonify({'message': 'Access denied'}), 403

        user_analyses = analyses.find(
            {'user_email': current_user['email']}
        ).sort('created_at', -1).limit(50)  # Get last 50 analyses
        
        history = []
        for analysis in user_analyses:
            result = analysis['analysis_result']
            history.append(result)
        
        return jsonify(history), 200
        
    except Exception as e:
        return jsonify({'message': f'Error fetching analysis history: {str(e)}'}), 500

@app.route('/analysis-history', methods=['POST'])
@token_required
def post_analysis_history(current_user):
    """
    Stores a new analysis result for the authenticated user.
    """
    try:
        data = request.get_json()
        if not data:
            return jsonify({'message': 'No data provided'}), 400

        # Extract required fields from the request body
        analysis_result = data.get('analysis_result')
        recommendations = data.get('recommendations')
        image_url = data.get('image_url') # Optional

        if not analysis_result or not recommendations:
            return jsonify({'message': 'Missing analysis_result or recommendations'}), 400

        # Create the record to be inserted into MongoDB
        analysis_record = {
            'user_id': str(current_user['_id']),
            'user_email': current_user['email'], # For easier querying
            'analysis_result': analysis_result,
            'recommendations': recommendations,
            'image_url': image_url,
            'timestamp': datetime.datetime.now() # Auto-generated timestamp
        }
        analyses.insert_one(analysis_record)
        return jsonify({'message': 'Analysis saved successfully'}), 201
    except Exception as e:
        return jsonify({'message': f'Error saving analysis: {str(e)}'}), 500

@app.route('/save-analysis', methods=['POST'])
@token_required
def save_analysis(current_user):
    try:
        if 'analysis' not in request.form:
            return jsonify({'message': 'No analysis data provided'}), 400
        
        if 'image' not in request.files:
            return jsonify({'message': 'No image file provided'}), 400
        
        # Parse analysis data
        import json
        analysis_data = json.loads(request.form['analysis'])
        
        # Save image file
        file = request.files['image']
        if file and allowed_file(file.filename):
            filename = secure_filename(f"saved_{uuid.uuid4()}_{file.filename}")
            filepath = os.path.join(UPLOAD_FOLDER, filename)
            file.save(filepath)
            
            # Store in database
            analysis_record = {
                'user_id': str(current_user['_id']),
                'user_email': current_user['email'],
                'image_path': filepath,
                'analysis_result': analysis_data,
                'saved_manually': True,
                'created_at': datetime.datetime.utcnow()
            }
            
            analyses.insert_one(analysis_record)
            
            return jsonify({'message': 'Analysis saved successfully'}), 200
        else:
            return jsonify({'message': 'Invalid file type'}), 400
            
    except Exception as e:
        return jsonify({'message': f'Error saving analysis: {str(e)}'}), 500

@app.route('/api/ai-advisor', methods=['POST'])
def ai_advisor():
    # =================================================================================
   # === V V V ACTION REQUIRED: PASTE YOUR **NEW** API KEYS IN THE 2 LINES BELOW V V V ===
    # =================================================================================

    # 1. Google Gemini API Key (must be set in environment or .env)
    GEMINI_API_KEY = os.environ.get("GOOGLE_API_KEY", "")

    # 2. OpenWeatherMap API Key (must be set in environment or .env)
    OPENWEATHER_API_KEY = os.environ.get("OPENWEATHER_API_KEY", "")

    # =================================================================================
    # === ^ ^ ^ ACTION REQUIRED: PASTE YOUR **NEW** API KEYS IN THE 2 LINES ABOVE ^ ^ ^ ===
    # =================================================================================

    # Configure the Gemini client
    try:
        genai.configure(api_key=GEMINI_API_KEY)
        model = genai.GenerativeModel('gemini-2.5-flash')
    except Exception as e:
        print(f"Error configuring Gemini: {e}")
        return jsonify({"error": "AI service is not configured correctly."}), 500

    # Get data from the Flutter app's request
    data = request.get_json()
    user_query = data.get('query')
    city = data.get('city')

    if not user_query or not city:
        return jsonify({"error": "A query and city are required to get advice."}), 400

    # Get real-time weather data
    weather_url = f"https://api.openweathermap.org/data/2.5/weather?q={city},IN&appid={OPENWEATHER_API_KEY}&units=metric"
    weather_text = f"The user is in {city}, India."
    try:
        weather_response = requests.get(weather_url).json()
        if weather_response.get('cod') == 200:
            temp = weather_response['main'].get('temp', 'N/A')
            humidity = weather_response['main'].get('humidity', 'N/A')
            weather_desc = weather_response['weather'][0].get('description', 'N/A')
            weather_text = f"Current weather in {city}: Temperature is {temp}°C, Humidity is {humidity}%, with {weather_desc}."
        else:
            weather_text = f"The user provided the city '{city}', but specific weather data could not be fetched. Assume general conditions for India at this time of year (August 31, 2025 - monsoon season)."
    except Exception as e:
        print(f"Error fetching weather: {e}")

    # --- Final, Highly-Structured Prompt ---
    prompt = f"""
    You are "DermaCare AI", an expert skincare advisor. Your task follows a strict two-step process.

    Step 1: Analyze the user's intent.
    Read the user's query and determine if its core subject is about skincare, skin health, dermatology, or cosmetics. Valid skincare queries can be short phrases (e.g., "oily skin", "acne scars", "dry patches") or full questions.

    Step 2: Respond based on the intent.
    - IF the subject IS about skincare, you MUST follow the response structure below precisely.
    - IF the subject is clearly NOT about skincare (e.g., it is a simple greeting like "hello", a question about history, or a request to write code), then you MUST politely decline. Your response in this case MUST be ONLY this exact sentence: "I am a skincare advisor and can only answer questions related to skin health and beauty. Please ask me something about skincare!"

    ---
    RESPONSE STRUCTURE FOR VALID SKINCARE ANSWERS:

    1.  **Greeting and Weather:** Start your response with a friendly greeting and immediately state the current weather from the context. Example: "Hello! The current weather in Mumbai is..."
    2.  **Acknowledge and Advise:** Acknowledge the user's specific query and then provide clear, step-by-step advice. Use Markdown for formatting.
    3.  **Safety Disclaimer:** End your entire response with this exact concluding paragraph: "Please remember, this is AI-generated advice. For any serious or persistent skin conditions, it is always best to consult a certified dermatologist in person."

    ---
    CONTEXT FOR YOUR RESPONSE:
    - Today's Date: August 31, 2025.
    - User's Location Context: India (monsoon season).
    - Real-time Weather Data: {weather_text}
    - CRITICAL SAFETY RULE: You are not a doctor. If a query describes a serious medical condition, your main advice should be to see a dermatologist.
    ---

    Now, analyze the following user query and provide your response based on all the rules above.

    USER'S QUESTION:
    "{user_query}"
    """

    try:
        response = model.generate_content(prompt)
        return jsonify({"response": response.text})
    except Exception as e:
        print(f"Error generating content from Gemini: {e}")
        return jsonify({"error": f"An error occurred with the AI service: {str(e)}"}), 500

# =========================
# AI Advisor History Routes
# =========================

@app.route('/advisor-history', methods=['POST'])
@token_required
def save_advisor_history(current_user):
    """Saves an AI advisor query and response for the authenticated user."""
    try:
        data = request.get_json()
        if not data or 'query' not in data or 'city' not in data or 'response' not in data:
            return jsonify({'message': 'Missing required fields: query, city, response'}), 400

        # Use device timestamp if provided, otherwise use server time
        timestamp = data.get('timestamp')
        if timestamp:
            # Parse the ISO string and ensure it's in UTC+5:30 for storage
            timestamp = datetime.datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            # Convert to UTC+5:30
            timestamp = timestamp.astimezone(datetime.timezone(datetime.timedelta(hours=5, minutes=30)))
        else:
            # Use current time in UTC+5:30
            timestamp = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=5, minutes=30)))

        history_item = {
            'user_email': current_user['email'],
            'query': data['query'],
            'city': data['city'],
            'response': data['response'],
            'timestamp': timestamp
        }

        advisor_history_collection.insert_one(history_item)
        return jsonify({'message': 'Advisor history saved successfully'}), 201

    except Exception as e:
        return jsonify({'message': f'Error saving advisor history: {str(e)}'}), 500

@app.route('/advisor-history', methods=['GET'])
@token_required
def fetch_advisor_history(current_user):
    """Fetches all AI advisor history for the authenticated user."""
    try:
        items = advisor_history_collection.find({'user_email': current_user['email']}).sort('timestamp', -1)
        history = []
        for item in items:
            timestamp = item.get('timestamp')
            if isinstance(timestamp, datetime.datetime):
                timestamp = timestamp.isoformat()

            history.append({
                'id': str(item['_id']),
                'query': item.get('query'),
                'city': item.get('city'),
                'response': item.get('response'),
                'timestamp': timestamp,
            })
        return jsonify(history), 200
    except Exception as e:
        return jsonify({'message': f'Error fetching advisor history: {str(e)}'}), 500

@app.route('/advisor-history', methods=['DELETE'])
@token_required
def delete_advisor_history(current_user):
    """Deletes selected AI advisor history entries for the authenticated user."""
    try:
        data = request.get_json()
        if not data or 'ids' not in data or not isinstance(data['ids'], list):
            return jsonify({'message': 'Missing or invalid "ids" field'}), 400

        try:
            object_ids = [ObjectId(item_id) for item_id in data['ids']]
        except Exception:
            return jsonify({'message': 'Invalid ID format in the list'}), 400

        result = advisor_history_collection.delete_many({
            '_id': {'$in': object_ids},
            'user_email': current_user['email']
        })

        return jsonify({'message': f'{result.deleted_count} items deleted successfully'}), 200

    except Exception as e:
        return jsonify({'message': f'Error deleting advisor history: {str(e)}'}), 500

@app.route('/')
def index():
    return "DermaCare Backend is running."

@app.route('/feedback', methods=['POST'])
@token_required
def submit_feedback(current_user):
    try:
        data = request.get_json()
        if not data or 'message' not in data or not data['message'].strip():
            return jsonify({'message': 'Feedback message is required'}), 400

        feedback_message = data['message'].strip()

        feedback_record = {
            'user_email': current_user['email'],
            'message': feedback_message,
            'timestamp': datetime.datetime.now()
        }

        result = feedback.insert_one(feedback_record)
        return jsonify({'message': 'Feedback submitted successfully', 'id': str(result.inserted_id)}), 201
    except Exception as e:
        return jsonify({'message': f'Error submitting feedback: {str(e)}'}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
