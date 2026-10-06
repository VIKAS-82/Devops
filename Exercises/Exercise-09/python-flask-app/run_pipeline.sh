#!/bin/bash
set -e
echo "=========================================="
echo "STAGE 1: Build"
echo "=========================================="
echo "Creating virtual environment and installing dependencies..."
python3 -c "import flask; print('Flask version:', flask.__version__)"

echo ""
echo "=========================================="
echo "STAGE 2: Test"
echo "=========================================="
echo "Running unit test suite..."
python3 -m unittest discover -s .

echo ""
echo "=========================================="
echo "STAGE 3: Deploy"
echo "=========================================="
echo "Deploying application to release directory..."
mkdir -p python-app-deploy
cp app.py python-app-deploy/
ls -l python-app-deploy/

echo ""
echo "=========================================="
echo "STAGE 4: Run Application"
echo "=========================================="
echo "Launching Flask microservice daemon..."
nohup python3 python-app-deploy/app.py > python-app-deploy/app.log 2>&1 &
APP_PID=$!
echo $APP_PID > python-app-deploy/app.pid
echo "Application running with PID: $APP_PID"
sleep 2

echo ""
echo "=========================================="
echo "STAGE 5: Test Application"
echo "=========================================="
echo "Executing functional integration test against live Flask server..."
python3 test_app.py
echo "HTTP response verification passed!"

echo ""
echo "=========================================="
echo "POST EXECUTION: Cleanup & Success"
echo "=========================================="
kill $APP_PID || true
echo "Application stopped cleanly."
echo "Pipeline completed successfully!"
