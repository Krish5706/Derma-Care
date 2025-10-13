import google.generativeai as genai
import os

# It's recommended to load the API key from environment variables
# for better security practices.
genai.configure(api_key=os.environ.get("GOOGLE_API_KEY", "AIzaSyBwuWcgn7JwPMWR158XIlnKtZlvbcaBzlU"))

models = genai.list_models()

for m in models:
    print(m.name)
