# Railway Deployment Guide - DermaCare ML Model

## ✅ Pre-Deployment Checklist

Your backend is now ready for Railway deployment! Here's what I've already configured:

### Files Created:
- ✅ **Procfile** - Tells Railway how to run your Flask app with Gunicorn
- ✅ **runtime.txt** - Specifies Python 3.10.13
- ✅ **.gitignore** - Prevents uploads folder and .env from being committed (also ignores large .keras model file)
- ✅ **download_model.py** - Downloads 233MB model from Google Drive at startup
- ✅ **Updated requirements.txt** - Added `gunicorn` and `requests`
- ✅ **Updated app.py** - Calls download_model on startup + reads PORT from environment

---

## 🚀 Step-by-Step Railway Deployment

### **Step 1: Initialize Git Repository (if not already done)**

```bash
cd c:\Users\vaghe\OneDrive\Desktop\Derma-Care
git init
git add .
git commit -m "Initial commit - ready for Railway deployment"
```

### **Step 2: Push to GitHub**

1. Create a new repository on GitHub: https://github.com/new
2. Name it: `derma-care-ml` or similar
3. Run these commands:

```bash
git remote add origin https://github.com/YOUR_USERNAME/derma-care-ml.git
git branch -M main
git push -u origin main
```

### **Step 3: Create Railway Project**

1. Go to https://railway.app
2. Sign up with GitHub (recommended)
3. Click **"New Project"**
4. Select **"Deploy from GitHub"**
5. Select your `derma-care-ml` repository
6. Railway auto-detects it's a Python project ✅

### **Step 4: Configure Environment Variables on Railway**

In Railway dashboard → **Variables** tab, add all these:

```
MONGO_URI=your_mongodb_connection_string_here
SECRET_KEY=generate_a_strong_random_string_here
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_API_KEY=your_gemini_api_key
OPENWEATHER_API_KEY=your_openweather_api_key
```

#### How to generate values:

**MONGO_URI** (from MongoDB Atlas):
- Go to MongoDB Atlas → Clusters → Connect
- Copy connection string: `mongodb+srv://username:password@cluster.mongodb.net/dermacare?retryWrites=true`

**SECRET_KEY** (generate random):
```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

**GOOGLE_CLIENT_ID & GOOGLE_API_KEY**:
- Already have these from your Flutter app config

**OPENWEATHER_API_KEY**:
- Sign up at https://openweathermap.org/api
- Get free API key from account

---

## 🤖 ML Model Hosting

**Your 233MB `.keras` model is hosted on Google Drive:**
```
https://drive.google.com/file/d/1Cl7RZEFL5YTjgjTMQDaBK66T17Y1tzSc/view?usp=sharing
```

### How It Works:
1. When your app starts on Railway, `download_model.py` automatically downloads the model
2. Model is cached in Railway's container filesystem
3. No need for Git LFS or GitHub size limits ✅
4. First deployment takes ~2-3 minutes (download time), subsequent restarts are instant

### Benefits of This Approach:
✅ **No GitHub limits** - 233MB file stays on Google Drive
✅ **Easy updates** - Just replace Google Drive file, redeploy
✅ **Fast deployment** - No need for Git LFS setup
✅ **Railway compatible** - Container has enough disk space

---

## 📊 Model Size Check

Your model (233MB) is downloaded from Google Drive at startup. 

**Railway container has 5GB disk space** - plenty for your model ✅

First deployment may take 2-3 minutes for download. Subsequent restarts are instant.

---

## 🌐 Update Your Flutter Frontend

Once deployed, Railway gives you a URL like:
```
https://derma-care-ml-prod.railway.app
```

Update your Flutter `config.dart`:

```dart
const String API_BASE_URL = 'https://your-railway-url.railway.app';
```

Or set it as an environment variable during build.

---

## ✅ Deployment Verification

After Railway deploys (watch the logs):

1. **Check health**: `https://your-railway-url.railway.app/`
2. **Test prediction endpoint**:
```bash
curl -X POST https://your-railway-url.railway.app/predict \
  -F "image=@test_image.jpg"
```

3. **View logs**: Railway Dashboard → Logs tab
   - Look for errors or warnings
   - Verify model loaded successfully

---

## 🐛 Common Issues & Fixes

### Issue: "Model file not found"
**Fix**: Ensure Google Drive link is accessible and public.
- Open link: https://drive.google.com/file/d/1Cl7RZEFL5YTjgjTMQDaBK66T17Y1tzSc/view?usp=sharing
- Check it's not private or expired
- If you replace the file, update the file ID in `download_model.py`

### Issue: "Download timeout" (first deployment)
**Fix**: This is normal. First deployment takes 2-3 minutes to download 233MB.
- Check Railway logs to see download progress
- Subsequent restarts are instant

### Issue: "Model file not found" after restart
**Fix**: Model is cached during deployment. If missing, Railway logs will show download errors.

### Issue: "Out of memory"
**Fix**: Switch to Railway Paid plan or use `tensorflow-cpu` (already done ✅)

### Issue: "CORS errors from Flutter"
**Fix**: Already enabled in app.py ✅, but verify:
```python
CORS(app, resources={r"/*": {"origins": "*"}})
```

### Issue: "Build takes too long"
**Fix**: Railway caches dependencies. Delete and redeploy if needed.

### Issue: "Port binding error"
**Fix**: App now reads PORT from environment ✅

---

## 📝 Cost Estimate

- **Free Tier**: $5 monthly credit (good for testing)
- **Production**: $5-20/month depending on:
  - RAM (512MB → 2GB+)
  - Database size
  - Traffic

---

## 🔒 Security Best Practices

1. ✅ Set `debug=False` in production (already done)
2. ✅ Use strong `SECRET_KEY`
3. ✅ Keep `.env` in `.gitignore`
4. ✅ Rotate API keys monthly
5. ✅ Monitor Railway logs for errors

---

## 📚 Additional Resources

- Railway Docs: https://docs.railway.app
- Flask Deployment: https://flask.palletsprojects.com/en/latest/deploying/
- MongoDB Atlas: https://www.mongodb.com/cloud/atlas
- TensorFlow Deployment: https://www.tensorflow.org/lite/guide/inference

---

## 🎉 Next Steps

1. Push code to GitHub
2. Create Railway project
3. Set environment variables
4. Deploy (automatic on push)
5. Update Flutter frontend URL
6. Test all endpoints

**All files are ready! You're good to go! 🚀**
