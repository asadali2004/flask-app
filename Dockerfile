# Use official Python image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy and install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy app files
COPY . .

# Run the application
CMD ["python", "app.py"]
