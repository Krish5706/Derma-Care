# 5.3 DATABASE DESIGN: ER DIAGRAM AND DATA FLOW

## Overview
The database uses MongoDB's document-based model, with collections representing entities. An ER diagram equivalent in NoSQL terms includes relationships via embedded documents and references.

## Key Collections (Entities)

### Users Collection
- **_id**: ObjectId (MongoDB auto-generated)
- **username**: String
- **email**: String (unique identifier)
- **password**: String (hashed, optional for Google auth)
- **google_id**: String (for Google OAuth)
- **profile_picture**: String (URL)
- **auth_provider**: String (e.g., 'google', 'local')
- **created_at**: DateTime

### Predictions Collection
- **_id**: ObjectId (MongoDB auto-generated)
- **user_email**: String (reference to Users.email)
- **image_binary**: Binary (stored image data)
- **image_mime**: String (e.g., 'image/jpeg')
- **prediction**: String (predicted skin condition)
- **confidence**: Float (confidence score)
- **created_at**: DateTime

### Chat_History Collection
- **_id**: ObjectId (MongoDB auto-generated)
- **user_email**: String (reference to Users.email)
- **title**: String (chat title)
- **messages**: Array of Objects (chat messages)
- **timestamp**: DateTime

### Advisor_History Collection
- **_id**: ObjectId (MongoDB auto-generated)
- **user_email**: String (reference to Users.email)
- **query**: String (user's query)
- **city**: String (user's city)
- **response**: String (AI response)
- **timestamp**: DateTime

### Feedback Collection
- **_id**: ObjectId (MongoDB auto-generated)
- **user_email**: String (reference to Users.email)
- **message**: String (feedback text)
- **timestamp**: DateTime

## Relationships
- **Predictions** and **Histories** (Chat_History, Advisor_History) reference **user_email** for user-specific data.
- All history collections are linked to the Users collection via the user_email field, enabling efficient querying of user-specific data.
- No embedded documents are used; relationships are handled via references for flexibility in a NoSQL environment.

## ER Diagram Equivalent (Text-Based)

```
+----------------+       +-------------------+
|     Users      |       |   Predictions     |
+----------------+       +-------------------+
| _id (ObjectId) |<------| _id (ObjectId)    |
| username       |       | user_email        |
| email          |       | image_binary      |
| password       |       | image_mime        |
| google_id      |       | prediction        |
| profile_picture|       | confidence        |
| auth_provider  |       | created_at        |
| created_at     |       +-------------------+
+----------------+
        |
        | (via user_email)
        |
        +-------------------+
        |   Chat_History    |
        +-------------------+
        | _id (ObjectId)    |
        | user_email        |
        | title             |
        | messages (array)  |
        | timestamp         |
        +-------------------+

        +-------------------+
        | Advisor_History   |
        +-------------------+
        | _id (ObjectId)    |
        | user_email        |
        | query             |
        | city              |
        | response          |
        | timestamp         |
        +-------------------+

        +-------------------+
        |     Feedback      |
        +-------------------+
        | _id (ObjectId)    |
        | user_email        |
        | message           |
        | timestamp         |
        +-------------------+
```

**Note**: In MongoDB, relationships are not enforced as in relational databases. The arrows indicate reference relationships via the `user_email` field.

## Data Flow Diagram

### High-Level Data Flow
1. **User Authentication**: User logs in via Google OAuth or local registration → User data stored in Users collection.
2. **Image Upload and Prediction**:
   - User uploads image via Flutter app → Sent to Flask backend `/predict` endpoint.
   - Backend processes image using ResNet50V2 model → Returns prediction and confidence.
   - Prediction data stored in Predictions collection with user_email reference.
3. **History Retrieval**:
   - User requests history → Backend queries collections by user_email → Returns user-specific data.
4. **AI Advisor Interaction**:
   - User submits query and city → Backend calls Gemini API with weather data → Response stored in Advisor_History.
5. **Chat and Feedback**:
   - Chat messages stored in Chat_History.
   - Feedback submitted and stored in Feedback collection.

### Detailed Data Flow

```
[Flutter App] --> [Flask Backend API] --> [MongoDB Collections]

User Uploads Image:
- POST /predict (image file)
  --> Process with ML Model
  --> Store in Predictions: {user_email, image_binary, prediction, confidence, created_at}
  --> Return result to user

User Views History:
- GET /history (authenticated)
  --> Query Predictions by user_email
  --> Return list of predictions with base64 images

AI Advisor Query:
- POST /api/ai-advisor (query, city)
  --> Fetch weather data from OpenWeatherMap
  --> Generate response via Gemini API
  --> Store in Advisor_History: {user_email, query, city, response, timestamp}
  --> Return response

Chat History:
- POST/GET /chat/history (messages, title)
  --> Store/Update in Chat_History: {user_email, title, messages, timestamp}

Feedback:
- POST /feedback (message)
  --> Store in Feedback: {user_email, message, timestamp}
```

### Data Flow Summary
- **Input**: User interactions (uploads, queries, messages) from Flutter app.
- **Processing**: Backend handles authentication, ML prediction, AI generation, and data storage/retrieval.
- **Storage**: MongoDB collections store user data, predictions, histories, and feedback.
- **Output**: Results returned to Flutter app for display.
- **Security**: All operations require JWT token authentication, ensuring data isolation by user_email.

This design supports scalability, flexibility, and efficient querying in a NoSQL environment, aligning with the app's requirements for user-specific data management and AI-powered features.
