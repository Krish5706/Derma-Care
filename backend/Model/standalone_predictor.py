import tensorflow as tf
import numpy as np
import json
import os

def predict_skin_condition(image_path, model_path, class_names_path, img_width=224, img_height=224):

    if not os.path.exists(model_path):
        return f"Error: Model file not found at {model_path}", 0.0
    if not os.path.exists(class_names_path):
        return f"Error: Class names file not found at {class_names_path}", 0.0
    if not os.path.exists(image_path):
        return f"Error: Image file not found at {image_path}", 0.0

    try:
        # Load the trained model
        model = tf.keras.models.load_model(model_path)

        # Load the class names
        with open(class_names_path, 'r') as f:
            class_names = json.load(f)

        # Load and preprocess the image
        image = tf.io.read_file(image_path)
        image = tf.image.decode_jpeg(image, channels=3)
        image = tf.image.resize(image, [img_width, img_height])
        image_batch = tf.expand_dims(image, 0) # Create a batch

        # The model expects preprocessed input. Use the ResNetV2 preprocessor.
        preprocessed_image = tf.keras.applications.resnet_v2.preprocess_input(image_batch)

        # Make prediction
        pred_probs = model.predict(preprocessed_image)

        # Get the predicted class index and confidence
        pred_index = np.argmax(pred_probs[0])
        confidence = np.max(pred_probs[0])

        # Get the predicted class name
        pred_class_name = class_names[pred_index]

        return pred_class_name, float(confidence)

    except Exception as e:
        return f"An error occurred: {e}", 0.0


if __name__ == '__main__':
    import argparse
    import os
    # Default paths to the model and class names in the current Model folder
    CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
    DEFAULT_MODEL_PATH = os.path.join(CURRENT_DIR, 'Ge_ResNet50V2_Model.keras')
    DEFAULT_CLASS_NAMES_PATH = os.path.join(CURRENT_DIR, 'skin_disease_class_names.json')

    parser = argparse.ArgumentParser(description='Predict skin condition from image using TensorFlow .keras model.')
    parser.add_argument('--model', type=str, default=DEFAULT_MODEL_PATH, help='Path to the .keras model file (default: Model folder)')
    parser.add_argument('--class_names', type=str, default=DEFAULT_CLASS_NAMES_PATH, help='Path to the class names .json file (default: Model folder)')
    parser.add_argument('--image', type=str, required=True, help='Path to the image file to predict')
    args = parser.parse_args()

    predicted_class, confidence_score = predict_skin_condition(
        image_path=args.image,
        model_path=args.model,
        class_names_path=args.class_names
    )

    if "Error" in predicted_class:
        print(predicted_class)
    else:
        print(f"Prediction complete.")
        print(f"   -> Predicted Condition: {predicted_class}")
        print(f"   -> Confidence Score:  {confidence_score:.2%}")